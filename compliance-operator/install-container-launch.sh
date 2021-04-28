#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]
do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done  
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

export OPERATORS=$DIR/../operators
export BUNDLE_ROOT=$DIR/..

podman run \
  -it --security-opt label=disable \
  -v ./:/host   -v /dev/fuse:/dev/fuse:rw \
  --mount=type=bind,src=$OPERATORS,dst=/var/lib/containers:rw \
  --mount=type=bind,src=$BUNDLE_ROOT,dst=bundle \
  --mount=type=bind,src=$KUBECONFIG,dst=/kubeconfig \
  -e KUBECONFIG=/kubeconfig \
  --rm --ulimit host --privileged \
  localhost/compliance-image install.sh "$@"

