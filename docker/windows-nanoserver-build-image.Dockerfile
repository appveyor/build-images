ARG BUILD_IMAGE=mcr.microsoft.com/windows/servercore:ltsc2019
ARG BASE_IMAGE=mcr.microsoft.com/windows/nanoserver:1809
FROM $BUILD_IMAGE as installer-env

ENV APPVEYOR_BUILD_AGENT_VERSION=7.0.2974

COPY ./scripts/Windows ./scripts

USER ContainerAdministrator

#RUN pwsh ./scripts/create_appveyor_user.ps1

#USER appveyor

RUN powershell ./scripts/install_path_utils.ps1
RUN powershell ./scripts/install_powershell_core.ps1
RUN powershell ./scripts/install_7zip.ps1
RUN powershell ./scripts/install_git.ps1
RUN powershell ./scripts/install_appveyor_build_agent_docker.ps1

FROM $BASE_IMAGE

USER ContainerAdministrator

ENV ProgramFiles="C:\Program Files" \
    LOCALAPPDATA="C:\Users\ContainerAdministrator\AppData\Local" \
    PSModuleAnalysisCachePath="$LOCALAPPDATA\Microsoft\Windows\PowerShell\docker\ModuleAnalysisCache" \
    PSCORE="$ProgramFiles\PowerShell\pwsh.exe"

COPY --from=installer-env ["C:/Program Files/PowerShell/7", "C:/Program Files/PowerShell"]
COPY --from=installer-env ["C:/Program Files/7-Zip", "C:/Program Files/7-Zip"]
COPY --from=installer-env ["C:/Program Files/Git", "C:/Program Files/Git"]
COPY --from=installer-env ["C:/Program Files/AppVeyor/BuildAgent", "C:/Program Files/AppVeyor/BuildAgent"]

# Set the path
RUN setx /M PATH "%PATH%;C:\Program Files\7-Zip;C:\Program Files\Git\cmd;C:\Program Files\Git\usr\bin;C:\Program Files\PowerShell"

# intialize powershell module cache
RUN pwsh \
        -NoLogo \
        -NoProfile \
        -Command " \
          $stopTime = (get-date).AddMinutes(15); \
          $ErrorActionPreference = 'Stop' ; \
          $ProgressPreference = 'SilentlyContinue' ; \
          while(!(Test-Path -Path $env:PSModuleAnalysisCachePath)) {  \
            Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
            if((get-date) -gt $stopTime) { throw 'timout expired'} \
            Start-Sleep -Seconds 6 ; \
          }"

ENTRYPOINT [ "C:\\Program Files\\AppVeyor\\BuildAgent\\appveyor-build-agent.exe" ]