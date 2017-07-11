FROM scratch
ADD alpine-minirootfs-3.6.1-armhf.tar.gz /
COPY .* /root/
RUN apk --no-cache add s6 bash bash-completion nano
