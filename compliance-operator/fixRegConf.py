#!/usr/bin/python

# This script will create a Machine Config that will update the node registries.conf
# by setting the mirror-by-digest-only flag to false for all mirrored registries,
# except the two openshift release mirrored registries.
# This is needed because not all operators support using digest-only to obtain images.

## Usage:
# 1. login using oc or set KUBECONFIG
# 2. ./fixRegConf.py | oc apply -f -

import os
import json
import urllib.parse

stream = os.popen('oc get machineconfig 99-worker-generated-registries -o json')

mcWorkerRegOrig = json.loads(stream.read())

srcdata= mcWorkerRegOrig['spec']['config']['storage']['files'][0]['contents']['source']

decodedsrc = urllib.parse.unquote(srcdata.replace('data:text/plain,',''))

newsrcdata = decodedsrc.replace("mirror-by-digest-only = true","mirror-by-digest-only = false")
newsrcdata = newsrcdata.replace("mirror-by-digest-only = false","mirror-by-digest-only = true",2)

mcWorkerReg = {}
mcWorkerReg['apiVersion'] = mcWorkerRegOrig['apiVersion']
mcWorkerReg['kind'] = mcWorkerRegOrig['kind']
mcWorkerReg['metadata'] = {}
mcWorkerReg['metadata']['label'] = {}
mcWorkerReg['metadata']['label']['machineconfiguration.openshift.io/role'] = 'worker'
mcWorkerReg['metadata']['name'] = '99-worker-z-registries'
mcWorkerReg['spec'] = mcWorkerRegOrig['spec']
mcWorkerReg['spec']['config']['storage']['files'][0]['contents']['source'] = 'data:text/plain,' + urllib.parse.quote(newsrcdata)

print(json.dumps(mcWorkerReg))
