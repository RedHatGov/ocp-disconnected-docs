#FROM registry.access.redhat.com/ubi8/ubi:latest

FROM quay.io/podman/stable
ENV PYCURL_SSL_LIBRARY=openssl

ENV LC_CTYPE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

LABEL \
    name="Mirror Operator Catalogue" \
    description="Utility for mirroring operators a la cart " \
    maintainer="RedHat4Gov Team"

USER root

RUN \
    curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo \
    https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_7/devel:kubic:libcontainers:stable.repo \
    && dnf install -y \
        jq \
        autoconf \
        automake \
        git \
        gcc \
        openssl-devel \
        bzip2-devel \
        libffi-devel \
        libtool \
        libmnl \
        zlib-devel \
        make \
        sqlite \
        vim \
        wget \
        which \
        ansible \
    && wget https://raw.githubusercontent.com/redhat-cop/openshift-disconnected-operators/d546d3b64e811c8fd24c70154da14a4e07f27a79/mirror-operator-catalogue.py \
    && chmod +x mirror-operator-catalogue.py \
    && wget https://raw.githubusercontent.com/arvin-a/openshift-disconnected-operators/master/known-bad-images \
    && wget https://raw.githubusercontent.com/arvin-a/openshift-disconnected-operators/master/image-content-source-template \
    && wget https://raw.githubusercontent.com/arvin-a/openshift-disconnected-operators/master/catalog-source-template \
    && wget https://www.python.org/ftp/python/3.7.6/Python-3.7.6.tgz \
    && tar xzvf Python-3.7.6.tgz \
    && rm -f Python-3.7.6.tgz \
    && cd Python-3.7.6 \
    && ./configure --enable-optimizations \
    && make install \
    && python3 -m pip install pyyaml jinja2 \
    && cd - \
    && rm -Rf Python-3.7.6 \
    && wget http://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.7.4/openshift-client-linux-4.7.4.tar.gz \
    && tar xzvf openshift-client-linux-4.7.4.tar.gz \
    && rm -f openshift-client-linux-4.7.4.tar.gz \
    && mv oc /usr/bin/ \
    && rm -f kubectl README.md \
    && dnf install -y skopeo \
    && sed -i 's/k8s\_file/k8s\-file/' /etc/containers/containers.conf \
    && dnf clean all

COPY ./entrypoint.sh ./bundle.sh ./offline-operator-list ./fixRegConf.py ./install.sh ./install-container-launch.sh ./results-container-launch.sh ./results.sh ./

ENTRYPOINT ["/entrypoint.sh"]
