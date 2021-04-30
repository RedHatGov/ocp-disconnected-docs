#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]
do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done  
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

export BUNDLE_ROOT=$DIR/..

podman run \
  -it --security-opt label=disable \
  -v /dev/fuse:/dev/fuse:rw \
  --mount=type=bind,src=$BUNDLE_ROOT,dst=bundle \
  --mount=type=bind,src=$KUBECONFIG,dst=/kubeconfig \
  -e KUBECONFIG=/kubeconfig \
  --rm --ulimit host --privileged \
  quay.io/redhatgov/compliance-disconnected:latest "$@"

