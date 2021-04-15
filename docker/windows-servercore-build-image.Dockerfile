ARG BASE_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2019
FROM $BASE_IMAGE

ENV APPVEYOR_BUILD_AGENT_VERSION=7.0.2974

COPY ./scripts/Windows ./scripts

# Install Chocolatey
RUN powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'));" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

RUN choco install -y powershell-core && \
    choco install -y 7zip.install && \
    choco install -y git && \
    choco install -y hg && \
    choco install -y svn

RUN powershell ./scripts/install_appveyor_build_agent_docker.ps1

ENTRYPOINT [ "C:\\Program Files\\AppVeyor\\BuildAgent\\appveyor-build-agent.exe" ]