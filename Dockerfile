FROM registry.svc.ci.openshift.org/openshift/release:golang-1.12 AS builder
WORKDIR /go/src/github.com/openshift/cluster-logging-operator

# COPY steps are in the reverse order of frequency of change
COPY cmd ./cmd
COPY version ./version
COPY scripts ./scripts
COPY files ./files
COPY vendor ./vendor
COPY manifests ./manifests
COPY Makefile ./Makefile
COPY pkg ./pkg

RUN make build

FROM centos:centos7
RUN INSTALL_PKGS=" \
      openssl \
      " && \
    yum install -y $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    mkdir /tmp/ocp-clo && \
    chmod og+w /tmp/ocp-clo
COPY --from=builder /go/src/github.com/openshift/cluster-logging-operator/bin/cluster-logging-operator /usr/bin/
COPY --from=builder /go/src/github.com/openshift/cluster-logging-operator/scripts/* /usr/bin/scripts/
RUN mkdir -p /usr/share/logging/
COPY --from=builder /go/src/github.com/openshift/cluster-logging-operator/files/ /usr/share/logging/

COPY --from=builder /go/src/github.com/openshift/cluster-logging-operator/manifests /manifests
RUN rm /manifests/art.yaml

# this is required because the operator invokes a script as `bash scripts/cert_generation.sh`
WORKDIR /usr/bin
ENTRYPOINT ["/usr/bin/cluster-logging-operator"]
LABEL io.k8s.display-name="OpenShift cluster-logging-operator" \
      io.k8s.description="This is a component of OpenShift Container Platform that manages the lifecycle of the Aggregated logging stack." \
      io.openshift.tags="openshift,logging,cluster-logging" \
      com.redhat.delivery.appregistry=true \
      maintainer="AOS Logging <aos-logging@redhat.com>"
