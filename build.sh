#/bin/bash
if  [[ "$(which jq)" = "" ]]; then
    whiptail --title "Missing Required File" --yesno "jq is required for this script to function.\nShould I install it for you?" 8 48 "$TZ"  3>&1 1>&2 2>&3
    exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
    apt-get update
    apt-get install -y jq
fi
TZ=""
while [ "$TZ" = "" ]
do
    TZ="America/Chicago"
    [[ -f TIMEZONE ]] && source TIMEZONE
    TZ=$(whiptail --inputbox "Default timezone" 8 78 "$TZ" --title "Alpine Builder" 3>&1 1>&2 2>&3)
    exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
    if [[ ! "$(grep -c -w "$TZ" root/zone.csv )" = "1" ]]; then
        TIMEZONES=( $(cat root/zone.csv | cut -d, -f3|sort| sed 's/\"//g'|awk '!/^ / && NF {print $1 " [] off"}') )
        TZ=$(whiptail --title "Timezone Config" --radiolist --separate-output "Select Timezone" 20 48 12 "${TIMEZONES[@]}" 3>&1 1>&2 2>&3)
        exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
    fi
done
echo 'export TZ="$TZ"' > TIMEZONE

[[ -f s6-tags.json ]] && rm s6-tags.json
wget -qO s6-tags.json https://api.github.com/repos/just-containers/s6-overlay/tags
eval "$(jq -r '.[0] | @sh "S6_VERSION=\(.name)"' s6-tags.json )"

TARGET_LIST=($(jq '.[]| "\(.tag) \(.branch)   on"' buildlist.json|sed 's/\"//g'))
BUILDLIST=$(whiptail --title "Alpine Build Menu" --checklist --separate-output "Select Version" 12 48 6 "${TARGET_LIST[@]}" 3>&1 1>&2 2>&3)
exitstatus=$?; if [ $exitstatus = 1 ]; then exit 1; fi
for RELEASE in $BUILDLIST; do
    BRANCH="$(jq '.[]|select(.tag == "'$RELEASE'")|.branch' buildlist.json| sed 's/\"//g')"
    [[ -f latest-releases.yaml ]] && rm latest-releases.yaml
    wget -q https://nl.alpinelinux.org/alpine/$BRANCH/releases/armhf/latest-releases.yaml
    ALPINE_VERSION=$(./yaml2json.py < latest-releases.yaml | jq '.[]|select(.flavor == "alpine-minirootfs")|.version'| sed 's/\"//g')
    ALPINE_BRANCH=$(./yaml2json.py < latest-releases.yaml | jq '.[]|select(.flavor == "alpine-minirootfs")|.branch'| sed 's/\"//g')
    MIRROR="http://dl-cdn.alpinelinux.org/alpine"
    PACKAGES="alpine-baselayout,alpine-keys,apk-tools,libc-utils"
    cat << EOF > options
export RELEASE="$ALPINE_BRANCH"
export MIRROR="$MIRROR"
export PACKAGES="$PACKAGES"
export BUILD_OPTIONS=(-b -s -t UTC -r $ALPINE_BRANCH -m $MIRROR -p $PACKAGES)
EOF

    cat << EOF > Dockerfile
FROM scratch
ADD alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz /
ADD s6-overlay-$S6_VERSION-armhf.tar.gz /
COPY root /root/
RUN apk --no-cache add bash bash-completion nano git tzdata
RUN chmod 0700 /root/bin/tzconfig && echo "$TZ" > /etc/timezone; cp /usr/share/zoneinfo/$TZ /etc/localtime && exit 0 ; exit 1
RUN apk del tzdata
ENTRYPOINT ["/init"]
CMD ["/bin/bash"]
EOF

    [[ ! -f s6-overlay-$S6_VERSION-armhf.tar.gz ]] && \
        wget -O s6-overlay-$S6_VERSION-armhf.tar.gz https://github.com/just-containers/s6-overlay/releases/download/$S6_VERSION/s6-overlay-armhf.tar.gz

    [[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz ]] && \
        wget https://nl.alpinelinux.org/alpine/$ALPINE_BRANCH/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz

    [[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.sha256 ]] && \
        wget -q https://nl.alpinelinux.org/alpine/$ALPINE_BRANCH/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.sha256

    [[ ! -f alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.asc ]] && \
        wget -q https://nl.alpinelinux.org/alpine/$ALPINE_BRANCH/releases/armhf/alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz.asc

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
    cat options
    docker build -t whw3/alpine:$ALPINE_VERSION .
    docker tag whw3/alpine:$ALPINE_VERSION whw3/alpine:$RELEASE
done
