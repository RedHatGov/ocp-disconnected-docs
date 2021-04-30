#!/bin/bash

unalias cp

while getopts a:b:d:m: flag
do
    case "${flag}" in
        a) AUTH=${OPTARG};;
        # json formatted auth token for registry login
        b) BUNDLE=${OPTARG};;
        # Operator bundle tarball
        d) DEST=${OPTARG};;
        # URL of target registry to upload to. Sometimes requires port appended to end of url
        m) MAPPING=${OPTARG};;
        # Path to mapping.txt file that was created during bundle creation.
    esac
done

function __startRegistry() {
  podman container stop registry
  podman container rm registry
  podman run -d \
  -p 5000:5000 \
  --name registry \
  -v ./bundle/operators:/var/lib/registry \
  registry:2
}

function __loadRegistry() {
  podman load < bundle/containers/registry.tar
}

function __stopRegistry() {
  podman container stop registry
  podman containre rm registry
}

function __buildSource() {
  # First grap the source server and namespace
  SOURCE=$(grep -oP '(?<=\=).*' <<< $1)
  # Second grab the digest of the image
  DIGEST=$(grep -oP '\@.*(?=\=)' <<< $1)
  echo "$SOURCE$DIGEST"
}

function __buildDestination() {
  # Grab the namespace of the referenced image
  NS=$(grep -oP '(?<=\=localhost:5000).*' <<< $1)
  echo "$DEST$NS"
}

function __upload() {
  for i in $(cat $MAPPING)
  do
    SRC=$(__buildSource $i)
    DST=$(__buildDestination $i)
    skopeo copy docker://$SRC docker://$DST --tls-verify=false --all --authfile=$AUTH
  done
}

__removeOH() {
  oc patch operatorhubs.config.openshift.io cluster -n openshift-marketplace \
    --type merge --patch '{"spec":{"sources":[{"disabled": true,"name": "truao"}]}}'
}

__updateOperatorSource() {
  sed -i "s/localhost/${DEST}/g" bundle/publish/olm-icsp.yaml
  sed -i "s/localhost/${DEST}/g" rh-catalog-source.yaml
  oc apply -f bundle/publish/olm-icsp.yaml
  oc apply -f bundle/publish/rh-catalog-source.yaml
}

__allowTags() {
  ./fixRegConf.py | oc apply -f -
}

__installOperator() {
  oc apply -f bundle/manifests/
}

function main() {
  __loadRegistry \
  && __startRegistry \
  && __upload \
  && __removeOH \
  && __updateOperatorSource \
  && __allowTags \
  && __installOperator
}
