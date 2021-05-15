#!/bin/bash -x

BUNDLE_DIR='bundle'
BUNDLE_NAME='compliance-bundle.tar.gz'
HOST_DIR='/host/'
AUTH_TOKEN=$1
AUTH_FILE='auth.json'

function __getContainers() {
  mkdir -p $BUNDLE_DIR/containers
  podman pull registry:2
  podman save registry:2 > $BUNDLE_DIR/containers/registry.tar
  podman pull quay.io/redhatgov/compliance-disconnected:latest
  podman save quay.io/redhatgov/compliance-disconnected:latest > $BUNDLE_DIR/containers/operator-mirror.tar
  podman pull registry.access.redhat.com/ubi8/ubi:latest 
  podman save registry.access.redhat.com/ubi8/ubi:latest > $BUNDLE_DIR/containers/ubi8.tar
}

function __getManifests() {
  mkdir -p $BUNDLE_DIR/manifests
  curl https://raw.githubusercontent.com/openshift/compliance-operator/master/deploy/ns.yaml -o $BUNDLE_DIR/manifests/ns.yaml
  curl https://raw.githubusercontent.com/openshift/compliance-operator/master/deploy/olm-catalog/operator-group.yaml -o $BUNDLE_DIR/manifests/og.yaml
  curl https://raw.githubusercontent.com/openshift/compliance-operator/master/deploy/olm-catalog/subscription.yaml -o $BUNDLE_DIR/manifests/sub.yaml
}


function __startRegistry() {
  podman container stop registry
  podman container rm registry
  mkdir -p operators
  podman run -d \
  -p 5000:5000 \
  --name registry \
  -v ./operators:/var/lib/registry \
  registry:2
}

function __stopRegistry() {
  podman container stop registry
  podman container rm registry
}

function __consolidate() {

  mkdir -p $BUNDLE_DIR
  cp -rn operators $BUNDLE_DIR/
  cp -rn publish $BUNDLE_DIR/

}

function __extractCreds() {
  RH_PS=$(echo $1 | jq -r '.auths."registry.redhat.io".auth' | base64 -d -)
  ID=$(grep -o -P "^.+(?=:)" <<< $RH_PS)
  PASS=$(grep -o -P "(?<=\:)(.+$)" <<< $RH_PS)
  echo "$ID $PASS"
}

function __podmanLogin() {
  podman login registry.redhat.io --username $1 --password $2
}

function __writeAuth() {
  echo $1 > auth.json
}

function __mirror() {
  ./mirror-operator-catalogue.py \
    --catalog-version 1.0.0 \
    --authfile $1 \
    --registry-olm localhost:5000 \
    --registry-catalog localhost:5000 \
    --operator-file ./offline-operator-list \
    --ocp-version 4.7 \
    --operator-channel 4.7 \
    --icsp-scope=namespace
}

function __copyScripts() {
  mkdir -p $BUNDLE_DIR/scripts
  cp install-container-launch.sh $BUNDLE_DIR/scripts/
  cp results-container-launch.sh $BUNDLE_DIR/scripts/
}

function bundle() {
  # Write Auth file
  __writeAuth ${AUTH_TOKEN} && \
  # Extract credentials
  read UN PASS < <(__extractCreds ${AUTH_TOKEN}) && \
  # Podman login
  __podmanLogin $UN $PASS && \
  # Start the registry
  __startRegistry \
  # Run the mirroring script
  __mirror $AUTH_FILE \
  # Stop the registry
  __stopRegistry \
  # Consolidate
  __consolidate && \
  # Get ansible
  #__getManifests && \
  # Get containers
  __getContainers && \
  # Grab launch script
  __copyScripts && \
  # Compress
  tar -czvf ${BUNDLE_NAME} ${BUNDLE_DIR} && \
  # Export
  mv ${BUNDLE_NAME} ${HOST_DIR}
}

bundle

