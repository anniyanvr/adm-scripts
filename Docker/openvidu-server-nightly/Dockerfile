FROM ubuntu:18.04

LABEL maintainer=carlos.ruizbal@gmail.com

# Install Java
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk

# Cleaning the house
RUN apt-get clean && \
    apt-get autoclean && \
    rm -Rf /tmp/* && \
    rm -Rf /var/lib/apt/lists/*

# Copy OpenVidu Server
COPY openvidu-server.jar /
COPY run.sh /run.sh

EXPOSE 4443
EXPOSE 8888

CMD [ "/run.sh" ]

