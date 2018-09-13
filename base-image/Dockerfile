FROM ubuntu:18.04
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl bash ca-certificates iproute2 jq tcpdump netcat moreutils \
    && rm -rf /var/lib/apt/lists/*
RUN curl -LO http://releases.cilium.io/v1.2.0/cilium-x86_64 && \
    chmod +x cilium-x86_64 && \
    mv cilium-x86_64 /usr/bin/cilium
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.11.3/bin/linux/amd64/kubectl && \
    chmod +x kubectl && mv kubectl /usr/bin/kubectl
CMD []
