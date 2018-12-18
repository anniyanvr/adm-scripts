#!/bin/bash -x
set -eu -o pipefail

KMS_VERSION=$1

# Stopping services
systemctl stop kurento-media-server
systemctl stop nginx
supervisorctl stop openvidu-server

# Get the tarball
aws s3 cp s3://openvidu-pro/openvidu-server-pro-latest.jar /opt/openvidu/openvidu-server.jar

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

# Removing old version OpenVidu Call
rm -rf /var/www/html/*

# Deploying
tar zxf /home/ubuntu/openvidu-call.tar.gz -C /var/www/html
chown -R www-data.www-data /var/www/html
rm /home/ubuntu/openvidu-call.tar.gz
cp ~/OpenViduCall-demos-config-file.json /var/www/html/ov_credentials.json

# Starting services
systemctl start kurento-media-server
systemctl start nginx
supervisorctl start openvidu-server
