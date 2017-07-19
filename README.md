# Alpine Mini-Root Base image
```
FROM scratch
ADD alpine-minirootfs-3.6.2-armhf.tar.gz /
COPY .* /root/
RUN apk --no-cache add s6 bash bash-completion nano
```

See https://www.alpinelinux.org/downloads/ for updated tarballs


***nano*** ./build.sh prior to running to update version info if newer tarball is released


```
FROM whw3/alpine
```

