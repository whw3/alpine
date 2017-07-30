#/bin/bash
if  [[ "$(which jq)" = "" ]]; then
	apt-get update
	apt-get install -y jq
fi
S6_VERSION="v1.19.1.1"
TZ="America/Chicago"
[[ -f latest-releases.yaml ]] && rm latest-releases.yaml
wget https://nl.alpinelinux.org/alpine/latest-stable/releases/armhf/latest-releases.yaml
ALPINE_VERSION=$(./yaml2json.py < latest-releases.yaml | jq '.[]|select(.flavor == "alpine-minirootfs")|.version'| sed 's/\"//g')
ALPINE_BRANCH=$(./yaml2json.py < latest-releases.yaml | jq '.[]|select(.flavor == "alpine-minirootfs")|.branch'| sed 's/\"//g')
RELEASE=$( echo $ALPINE_BRANCH|sed 's/^v//')
MIRROR="http://dl-cdn.alpinelinux.org/alpine"
PACKAGES="alpine-baselayout,alpine-keys,apk-tools,libc-utils"
cat << EOF > options 
export RELEASE="$ALPINE_BRANCH"
export MIRROR="$MIRROR"
export PACKAGES="$PACKAGES"
export BUILD_OPTIONS=(-b -s -t UTC -r $ALPINE_BRANCH -m $MIRROR -p $PACKAGES)
export TAGS=(whw3/alpine:$ALPINE_VERSION whw3/alpine:$RELEASE whw3/alpine:latest)
EOF

cat << EOF > Dockerfile
FROM scratch
ADD alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz /
ADD s6-overlay-$S6_VERSION-armhf.tar.gz /
COPY .* /root/
RUN apk --no-cache add bash bash-completion nano git 
RUN apk --no-cache add tzdata ; \
cp /usr/share/zoneinfo/$TZ /etc/localtime; \
echo "$TZ" > /etc/timezone; \
apk del tzdata
ENTRYPOINT ["/init"]
EOF

[[ ! -f s6-overlay-$S6_VERSION-armhf.tar.gz ]] && \
    wget -O s6-overlay-$S6_VERSION-armhf.tar.gz https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-armhf.tar.gz

[[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz ]] && \
  wget https://nl.alpinelinux.org/alpine/$ALPINE_BRANCH/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz

[[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.sha256 ]] && \
  wget https://nl.alpinelinux.org/alpine/$ALPINE_BRANCH/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.sha256
 
[[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.asc ]] && \
  wget https://nl.alpinelinux.org/alpine/$ALPINE_BRANCH/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.asc

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
docker tag whw3/alpine whw3/alpine:$RELEASE
docker tag whw3/alpine whw3/alpine:$ALPINE_VERSION
