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

[[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.sha256 ]] && \
  wget https://nl.alpinelinux.org/alpine/v$RELEASE/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.sha256
 
[[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.asc ]] && \
  wget https://nl.alpinelinux.org/alpine/v$RELEASE/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.asc

if [[  $(sha256sum -c  alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.sha256) ]] ; then
    echo "Checksum: OK"
else
    echo "Checksum: INVALID...Build Terminated"
    exit 2
fi
if [[ ! $(gpg --fingerprint 293ACD0907D9495A 2>/dev/null) ]] ; then 
    echo "Importing NCOPA key"
    gpg --import ncopa.asc
fi

NCOPA_FPR=$( gpg --with-colons --fingerprint 293ACD0907D9495A 2>/dev/null | grep fpr | cut -d ':' -f 10 )
gpg --verify alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.asc alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz  &>SIGNATURE
FPR=$(grep fingerprint SIGNATURE|sed 's/Primary key fingerprint: //;s/ //g')
rm SIGNATURE
if [[ "$FPR" = "$NCOPA_FPR" ]]; then
    echo "Signature: OK"
else
    echo "Signature: Failed Valitdation...Build Terminated"
    exit 2
fi
echo "Building..."
docker build -t whw3/alpine .
