FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bc \
    bison \
    build-essential \
    ca-certificates \
    curl \
    flex \
    g++-multilib \
    gcc-multilib \
    git \
    gnupg \
    lib32ncurses6 \
    lib32stdc++6 \
    libffi-dev \
    libssl-dev \
    libxml2 \
    libxml2-utils \
    openjdk-17-jdk \
    python3 \
    python3-dev \
    python3-pip \
    rsync \
    unzip \
    xz-utils \
    zip \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo \
    && chmod 0755 /usr/local/bin/repo

WORKDIR /workspace/device_tree_boston

CMD ["/bin/bash"]
