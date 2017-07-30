# Alpine Mini-Root Base image
```
FROM scratch
ADD alpine-minirootfs-3.6.2-armhf.tar.gz /
ADD s6-overlay-v1.19.1.1-armhf.tar.gz /
COPY .* /root/
RUN apk --no-cache add bash bash-completion nano git 
RUN apk --no-cache add tzdata ; \
cp /usr/share/zoneinfo/America/Chicago /etc/localtime; \
echo "America/Chicago" > /etc/timezone; \
apk del tzdata
ENTRYPOINT ["/init"]
```

* <s>See https://www.alpinelinux.org/downloads/ for updated mini-root tarballs</s>
* <s>See https://github.com/just-containers/s6-overlay/releases for updated s6-overlay tarballs</s>

<s>***nano*** ./build.sh prior to running to update version info if newer tarballs are released</s>

***Script automagically updates to find the latest versions of the required packages now***

Now prompts to adjust the time zone.
See the demo at https://timezonedb.com/ is you don't know your timezone. 
```
FROM whw3/alpine
```

