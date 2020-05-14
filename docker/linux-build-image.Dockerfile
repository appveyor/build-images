ARG BASE_IMAGE=mcr.microsoft.com/powershell:ubuntu-18.04
FROM $BASE_IMAGE

ENV APPVEYOR_BUILD_AGENT_VERSION=7.0.2882
ENV IS_DOCKER=true
ENV TERM=xterm-256color

COPY ./scripts/Ubuntu ./scripts

RUN ./scripts/dockerconfig.sh

USER appveyor

CMD [ "/bin/bash", "/scripts/entrypoint.sh" ]