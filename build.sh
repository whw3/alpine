#/bin/bash
#ALPINE_VERSION="3.5.2"
#RELEASE="3.5" 
ALPINE_VERSION="3.6.2"
RELEASE="3.6"
MIRROR="http://dl-cdn.alpinelinux.org/alpine"
PACKAGES="alpine-baselayout,alpine-keys,apk-tools,libc-utils"

cat << EOF > options 
export RELEASE="v$RELEASE"
export MIRROR="$MIRROR"
export PACKAGES="$PACKAGES"
export BUILD_OPTIONS=(-b -s -t UTC -r v$RELEASE -m $MIRROR -p $PACKAGES)
export TAGS=(whw3/alpine:$RELEASE whw3/alpine:latest)
EOF

cat << EOF > Dockerfile
FROM scratch
ADD alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz /
COPY .* /root/
RUN apk --no-cache add s6 bash bash-completion nano
EOF

[[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz ]] && \
  wget https://nl.alpinelinux.org/alpine/v$RELEASE/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz

docker build -t whw3/alpine .
