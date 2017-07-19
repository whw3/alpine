# Alpine Mini-Root Base image
```
FROM scratch
ADD alpine-minirootfs-$ALPINE_VERSION-armhf.tar.gz /
ADD s6-overlay-$S6_VERSION-armhf.tar.gz /
COPY .* /root/
RUN apk --no-cache add bash bash-completion nano
ENTRYPOINT ["/init"]
```

* See https://www.alpinelinux.org/downloads/ for updated mini-root tarballs
* See https://github.com/just-containers/s6-overlay/releases for updated s6-overlay tarballs

***nano*** ./build.sh prior to running to update version info if newer tarballs are released


```
FROM whw3/alpine
```

