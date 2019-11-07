FROM hashicorp/packer:1.4.4
MAINTAINER appveyor.com
COPY . /build-images/
RUN apk --no-cache add curl
WORKDIR /build-images
ENTRYPOINT [ "/build-images/build.sh" ]