FROM hashicorp/packer:light
MAINTAINER appveyor.com
COPY . /build-images/
WORKDIR /build-images
ENTRYPOINT [ "/build-images/build.sh" ]