FROM mcr.microsoft.com/powershell:ubuntu-18.04
MAINTAINER appveyor.com
COPY . /build-images/
RUN apt-get update && apt-get install -y wget unzip
RUN wget https://appveyordownloads.blob.core.windows.net/packer/packer-linux-1.5-azure-fix.zip && unzip packer-linux-1.5-azure-fix.zip -d /usr/bin && chmod +x /usr/bin/packer
WORKDIR /build-images
ENTRYPOINT [ "/build-images/build.sh" ]