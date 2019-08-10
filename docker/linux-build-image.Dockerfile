ARG BASE_IMAGE=mcr.microsoft.com/powershell:ubuntu-18.04
FROM $BASE_IMAGE

ENV APPVEYOR_BUILD_AGENT_VERSION=7.0.2353

COPY ./scripts/Ubuntu ./scripts

RUN apt-get update && apt-get install -y curl git mercurial subversion

RUN ./scripts/dockerconfig.sh

ENTRYPOINT [ "/opt/appveyor/build-agent/appveyor-build-agent" ]