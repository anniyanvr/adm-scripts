FROM ubuntu:18.04

LABEL maintainer=carlos.ruizbal@gmail.com

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    git \
    curl \
    jq \
    zip \
    openjdk-11-jdk \
    python \
    python-pip \
    pwgen \
    lsb-release \
    maven \
    awscli \
    python-lxml \
    openssh-client \
    ffmpeg

# Installing nodejs
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /root/.bashrc

# Cleaning the house
RUN apt-get clean && \
    apt-get autoclean && \
    rm -Rf /tmp/* && \
    rm -Rf /var/lib/apt/lists/*