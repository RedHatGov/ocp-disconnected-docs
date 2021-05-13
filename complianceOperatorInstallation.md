# Disconnected OpenShift Compliance Operator Installation

## Overview

This guide is intended to demonstrate how to install the OpenShift [Compliance Operator](https://github.com/openshift/compliance-operator) into disconnected OpenShift environments.

The process of installing the OpenShift Compliance Operator can be broke down into three major steps:
1. Bundling (Internet Connected)
2. Mirroring (Disconnected)
3. Installation (Disconnected)

## Prereq

1. podman on the disconnected and internet connected hosts.

## Bundling

Perform the following steps on an internet connected host.

1. Clone the (unofficial) OpenShift Operator mirroring utility:  
```
git clone https://github.com/RedHatGov/ocp-disconnected-docs.git
cd ocp-disconnected-docs/
git checkout -t origin/compliance-operator
```
2. Retrieve OpenShift Pull Secret from: https://cloud.redhat.com/openshift/install/pull-secret

3. Run Compliance Operator convenience bundler:
```
./container/bundle-container-launch.sh ./bundle.sh '<< Pull Secret>>'
```
*Note, ensure pull secret is entered between literals.
*Note, This process bundles the latest version of operators. Refer to the [openshift-disconnected-operators'](https://github.com/redhat-cop/openshift-disconnected-operators) README for advanced usage.

4. After the previous command is finished,  `compliance-bundle.tar.gz` will be output to your current directory. Move this bundle to the disconnected host.

5. From the disconnected host, extract the bundle and descend into it:  
```
tar xzvf compliance-bundle.tar.gz
cd bundle
```

6. Mirror, Install, and use the compliance operator to scan the target Openshift cluster:
Note: Substitute the values of the -a and -d flags in the following command.

```
./bundle/scripts/install-container-launch.sh -a << path to json auth file >> -d << mirror.registry.name:port >>
```


