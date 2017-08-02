# Alpine Mini-Root Base image
Alpine base-image configured with
* bash
* nano
* git
* s6-overlay
* properly set timezone configuration. Can be reconfigured inside container by running ***/root/bin/tzconfig***

### Assumptions
* home for docker build images is ***/srv/docker***

To build the image(s) run ***/srv/docker/alpine/build.sh***
```
mkdir -p /srv/docker
cd /srv/docker
git clone https://github.com/whw3/alpine.git
cd alpine
chmod 0700 build.sh
./build.sh
```
