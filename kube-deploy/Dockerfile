# FROM golang:1.10
# MAINTAINER Ivan Shvedunov <ivan4th@gmail.com>

# ENV KUSTOMIZE_COMMIT c9a8bc1121c4263d9d09408897d015156b59377f

# RUN mkdir -p /go/src/github.com/kubernetes-sigs && \
#     git clone https://github.com/kubernetes-sigs/kustomize.git \
#               /go/src/github.com/kubernetes-sigs/kustomize && \
#     cd /go/src/github.com/kubernetes-sigs/kustomize && \
#     CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' .

FROM alpine:3.8
MAINTAINER Ivan Shvedunov <ivan4th@gmail.com>

ENV KUBECTL_VERSION v1.13.2
ENV KUBECTL_SHA1 96c123c1c7d90eb0cd7224efd10340f5fd714c85
ENV KUSTOMIZE_URL https://github.com/kubernetes-sigs/kustomize/releases/download/v1.0.11/kustomize_1.0.11_linux_amd64
ENV KUSTOMIZE_SHA256 2b21b44f0245ac774f0b35e5181fd8ad7fc42a9426bc0bbfe82a75bea286b48b

# COPY --from=0 /go/src/github.com/kubernetes-sigs/kustomize/kustomize /usr/local/bin/kustomize

ENV YQ_URL https://github.com/mikefarah/yq/releases/download/2.2.1/yq_linux_amd64
ENV YQ_SHA256 54443f0e9796dfb8423a6e33b8175a0f77b8bb0eb55db820ecb84098db2c0ed4

# coreutils are needed for base64 --decode
# busybox only supports base64 -d which is not compatible with Mac.
RUN apk add --update ca-certificates dumb-init bash gnupg coreutils && \
    apk add --update -t deps curl && \
    curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl && \
    echo "${KUBECTL_SHA1}  /usr/local/bin/kubectl" | sha1sum -c && \
    chmod +x /usr/local/bin/kubectl && \
    apk del --purge deps && \
    rm /var/cache/apk/* && \
    wget -O /usr/local/bin/kustomize "${KUSTOMIZE_URL}" && \
    echo "${KUSTOMIZE_SHA256}  /usr/local/bin/kustomize" | sha256sum -c && \
    chmod +x /usr/local/bin/kustomize && \
    wget -O /usr/local/bin/yq "${YQ_URL}" && \
    echo "${YQ_SHA256}  /usr/local/bin/yq" | sha256sum -c && \
    chmod +x /usr/local/bin/yq

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
