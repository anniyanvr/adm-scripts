#!/bin/bash -x
set -eu -o pipefail

# Vars
OV_RELEASE=$1
DEMOS_RELEASE=$2
OVC_RELEASE=$3
KMS_VERSION=$4
CF_RELEASE=master
WORKDIR=$(mktemp -d --suffix .ov)
TARGETDIR=/var/www/html

# Stopping services
systemctl stop nginx
systemctl stop kurento-media-server
supervisorctl stop openvidu-server
supervisorctl stop js-java
supervisorctl stop classroom-demo

# Check if KMS is up to date
if ! grep -q ${KMS_VERSION} /etc/apt/sources.list.d/kurento.list; then
	
	# Purge KMS
	for pkg in \
		'^(kms|kurento).*' \
		ffmpeg \
		'^gir1.2-gst.*1.5' \
		'^(lib)?gstreamer.*1.5.*' \
		'^lib(nice|s3-2|srtp|usrsctp).*' \
		'^srtp-.*' \
		'^openh264(-gst-plugins-bad-1.5)?' \
		'^openwebrtc-gst-plugins.*' \
		'^libboost-?(filesystem|log|program-options|regex|system|test|thread)?-dev' \
		'^lib(glib2.0|glibmm-2.4|opencv|sigc++-2.0|soup2.4|ssl|tesseract|vpx)-dev' \
		uuid-dev
	do apt-get -y purge --auto-remove $pkg ; done
	
	# Install newer version of KMS
	echo "deb [arch=amd64] http://ubuntu.openvidu.io/${KMS_VERSION} xenial kms6" > /etc/apt/sources.list.d/kurento.list
	apt-get update
	apt-get install -y kurento-media-server
fi

# Configuring Media Server
MY_IP=$(curl ifconfig.co)
cat >/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini<<EOF
stunServerAddress=${MY_IP}
stunServerPort=3478
EOF

## Common tasks
# clone the repos
cd $WORKDIR
git clone https://github.com/OpenVidu/openvidu-tutorials.git
cd openvidu-tutorials
git checkout v$DEMOS_RELEASE
cd ..

# OpenVidu Server
wget https://github.com/OpenVidu/openvidu/releases/download/v${OV_RELEASE}/openvidu-server-${OV_RELEASE}.jar -O /opt/openvidu/openvidu-server.jar

# Basic Videoconference (openvidu-insecure-js)
mkdir -p $TARGETDIR/basic-videoconference
cp -rav $WORKDIR/openvidu-tutorials/openvidu-insecure-js/web/* $TARGETDIR/basic-videoconference
wget https://github.com/OpenVidu/openvidu/releases/download/v${OV_RELEASE}/openvidu-browser-${OV_RELEASE}.js -O $TARGETDIR/basic-videoconference/openvidu-browser-${OV_RELEASE}.js

# Basic Webinar (openvidu-js-java)
mkdir -p $TARGETDIR/basic-webinar
wget https://github.com/OpenVidu/openvidu-tutorials/releases/download/v${DEMOS_RELEASE}/openvidu-js-java-${DEMOS_RELEASE}.jar -O $TARGETDIR/basic-webinar/openvidu-js-java.jar

# Getaroom
mkdir -p $TARGETDIR/getaroom 
cp -rav $WORKDIR/openvidu-tutorials/openvidu-getaroom/web/* $TARGETDIR/getaroom
wget https://github.com/OpenVidu/openvidu/releases/download/v${OV_RELEASE}/openvidu-browser-${OV_RELEASE}.js -O $TARGETDIR/getaroom/openvidu-browser-${OV_RELEASE}.js

# Openvidu Classroom
mkdir -p $TARGETDIR/classroom
wget https://github.com/OpenVidu/classroom-demo/releases/download/v${DEMOS_RELEASE}/classroom-demo-${DEMOS_RELEASE}.war -O $TARGETDIR/classroom/classroom-demo.jar

# Openvidu Call
mkdir -p $TARGETDIR/openvidu-call
rm -rf $TARGETDIR/openvidu-call/* || true
wget https://github.com/OpenVidu/openvidu-call/releases/download/v${OVC_RELEASE}/openvidu-call-demos-${OVC_RELEASE}.tar.gz -O $WORKDIR/ovc.tar.gz
tar zxf $WORKDIR/ovc.tar.gz -C $TARGETDIR/openvidu-call
cp ~/OpenViduCall-demos-config-file.json $TARGETDIR/openvidu-call/ov-settings.json

# Web Page
git clone https://github.com/OpenVidu/openvidu-cloud-devops
cd openvidu-cloud-devops
git checkout $CF_RELEASE
cp -rav web-demos-openvidu/* $TARGETDIR/

# Starting services
systemctl start nginx
systemctl start kurento-media-server
supervisorctl start openvidu-server
supervisorctl start js-java
supervisorctl start classroom-demo

# Cleaning the house
rm -rf $WORKDIR
