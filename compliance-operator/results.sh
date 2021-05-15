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

function __getScanName() {

  oc get compliancescans -o json | jq '.items[].status.resultsStorage' | jq -r '.name'

}

function __getPVC() {
  for i in $1
  do
    oc get pvc $i -o json | jq -r '.metadata.name'
  done
}

function __getResults() {
  digest=$2
  for i in $1
  do
    cat << EOF |
apiVersion: "v1"
kind: Pod
metadata:
  name: pv-extract
spec:
  containers:
    - name: pv-extract-pod
      image: registry.redhat.io/rhel8/ubi@${digest}
      command: ["sleep", "3000"]
      volumeMounts:
        - mountPath: "/scan-results"
          name: scan-vol
  volumes:
    - name: scan-vol
      persistentVolumeClaim:
        claimName: ${i}
EOF
    oc apply -f -

    until oc get pod pv-extract -o json | jq -r '.status.containerStatuses[].state' | grep running
    do 
      echo "Starting Results Extraction Pod"
      sleep 5
    done 

    oc cp pv-extract:/scan-results ./workdir/scan_results

    cat << EOF |
apiVersion: "v1"
kind: Pod
metadata:
  name: pv-extract
spec:
  containers:
    - name: pv-extract-pod
      image: registry.redhat.io/rhel8/ubi@${digest}
      command: ["sleep", "3000"]
      volumeMounts:
        - mountPath: "/scan-results"
          name: scan-vol
  volumes:
    - name: scan-vol
      persistentVolumeClaim:
        claimName: ${i}
EOF
    oc delete -f -
    until ! oc get pod -o json | jq '.items[].metadata.name' | grep pv-extract
    do 
      echo "Deleting Results Extraction Pod"
      sleep 5
    done 
  done
}

function __loadUBI() {
  podman load < bundle/containers/ubi8.tar
  podman tag registry.access.redhat.com/ubi8/ubi ${DEST}/rhel8/ubi:latest
  podman push ${DEST}/rhel8/ubi:latest --tls-verify=false --authfile=auth.json
}

function __getDigest() {

  skopeo inspect docker://${DEST}/rhel8/ubi --tls-verify=false --authfile auth.json | \
     jq -r '.Digest'

}

function results() {

  name=$(__getScanName) && \
  pvc=$(__getPVC "${name}") && \
  __loadUBI && \
  digest=$(__getDigest) && \
  __getResults "${pvc}" "${digest}"

}

results

