#!/bin/bash -x

while getopts a:d: flag
do
    case "${flag}" in
        a) AUTH=${OPTARG};;
        # json formatted auth token for registry login
        d) DEST=${OPTARG};;
        # URL of target registry to upload to. Sometimes requires port appended to end of url
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
  podman container rm registry
}

function __buildSource() {
  # First grap the source server and namespace
  SOURCE=$(grep -oP '(?<=\=).*' <<< $1)
  # Second grab the digest of the image
  DIGEST=$(grep -oP '\@.*(?=\=)' <<< $1)
  if [ ! -z ${DIGEST} ]
  then
    echo "$SOURCE$DIGEST"
  else
    echo "$SOURCE"
  fi
}

function __buildDestination() {
  # Grab the namespace of the referenced image
  NS=$(grep -oP '(?<=\=localhost:5000).*' <<< $1)
  echo "$DEST$NS"
}

function __upload() {
  for i in $(cat bundle/publish/mapping.txt)
  do
    SRC=$(__buildSource $i)
    DST=$(__buildDestination $i)
    skopeo copy docker://$SRC docker://$DST --tls-verify=false --all --authfile=auth.json
  done
  skopeo copy docker://localhost:5000/custom-redhat-operator-index:1.0.0 docker://${DEST}/custom-redhat-operator-index:1.0.0 --tls-verify=false --all --authfile=auth.json
}

__removeOH() {
  oc patch operatorhubs.config.openshift.io cluster -n openshift-marketplace \
    --type merge --patch '{"spec":{"sources":[{"disabled": true,"name": "truao"}]}}'
}

__updateOperatorSource() {
  sed -i "s/localhost\:5000/${DEST}/g" bundle/publish/olm-icsp.yaml
  sed -i "s/localhost\:5000/${DEST}/g" bundle/publish/rh-catalog-source.yaml
  oc apply -f bundle/publish/olm-icsp.yaml
  oc apply -f bundle/publish/rh-catalog-source.yaml
}

__allowTags() {
  ./fixRegConf.py | oc apply -f -
}

__installOperator() {
  oc apply -f bundle/manifests/
}

function __writeAuth() {
  echo $1 > auth.json
}

function __runScan() {
  cat << EOF |
apiVersion: compliance.openshift.io/v1alpha1
kind: ScanSetting
metadata:
  name: periodic-setting
  namespace: openshift-compliance
schedule: "0 1 * * *"
rawResultStorage:
    size: "2Gi"
    rotation: 5
roles:
  - worker
  - master
---
apiVersion: compliance.openshift.io/v1alpha1
kind: ScanSettingBinding
metadata:
  name: periodic-cis
  namespace: openshift-compliance
profiles:
  # Node checks
  - name: ocp4-cis-node
    kind: Profile
    apiGroup: compliance.openshift.io/v1alpha1
  # Platform checks
  - name: ocp4-cis
    kind: Profile
    apiGroup: compliance.openshift.io/v1alpha1
settingsRef:
  name: periodic-setting
  kind: ScanSetting
  apiGroup: compliance.openshift.io/v1alpha1
EOF
oc apply -f -

}

function __crdCheck() {

  until oc get crd | grep compliance
  do
    echo "Waiting for Compliance Operator Installation"
    sleep 5
  done

}

function install() {
  __writeAuth "${AUTH}" && \
  __loadRegistry && \
  __startRegistry && \
  __upload && \
  __removeOH && \
  __updateOperatorSource && \
  __allowTags && \
  __installOperator && \
  __crdCheck && \
  __runScan
}

install

