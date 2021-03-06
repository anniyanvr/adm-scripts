#!/bin/bash -x

echo "##################### EXECUTE: openvidu_ci_container_entrypoint #####################"

[ -n "$1" ] || { echo "No script to run specified. Need one to run after preparing the environment"; exit 1; }
BUILD_COMMAND=$@

DIST=$(lsb_release -c)
DIST=$(echo ${DIST##*:} | tr -d ' ' | tr -d '\t')

# Configure SSH keys
if [ -f "$GITHUB_PRIVATE_RSA_KEY" ]; then
    mkdir -p /root/.ssh
    cp $GITHUB_PRIVATE_RSA_KEY /root/.ssh/git_id_rsa
    chmod 600 /root/.ssh/git_id_rsa
    cat >> /root/.ssh/config <<-EOF
      StrictHostKeyChecking no
      User $( echo jenkinsopenvidu)
      IdentityFile /root/.ssh/git_id_rsa
EOF
    if [ "$DIST" = "xenial" ]; then
      cat >> /root/.ssh/config<<-EOF
        KexAlgorithms +diffie-hellman-group1-sha1
EOF
    fi
fi

# Configure GitHub Credentials
if [ -f "$CONTAINER_GIT_CONFIG" ]; then 
    cp $CONTAINER_GIT_CONFIG /root/.gitconfig
fi

# GPG Block
if [ -f "$GPG_PRIVATE_BLOCK" ]; then
  gpg --import --batch $GPG_PRIVATE_BLOCK
fi

# AWS region
if [ -f "$AWS_CONFIG" ]; then
  mkdir -p /root/.aws
  cp $AWS_CONFIG /root/.aws/config
fi

export PATH=$PATH:$ADM_SCRIPTS

for CMD in $BUILD_COMMAND; do
  echo "Running command: $CMD"
  $CMD || exit 1
done
