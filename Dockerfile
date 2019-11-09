FROM mcr.microsoft.com/powershell:ubuntu-18.04
MAINTAINER appveyor.com
COPY . /build-images/
RUN apt-get update && apt-get install -y wget unzip
RUN wget https://releases.hashicorp.com/packer/1.4.5/packer_1.4.5_linux_amd64.zip && unzip packer_1.4.5_linux_amd64.zip -d /usr/bin
WORKDIR /build-images
ENTRYPOINT [ "/build-images/build.sh" ]