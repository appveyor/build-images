# https://github.com/microsoft/azure-pipelines-image-generation/blob/master/images/win/scripts/Installers/Update-AndroidSDK.ps1

$ErrorActionPreference = 'SilentlyContinue'

$sdk_root = Join-Path ${env:ProgramFiles(x86)} "Android\android-sdk"
$ndk_root = Join-Path $env:SystemDrive "Microsoft\AndroidNDK64\"
if (-not (Test-Path $ndk_root)) {
    $ndk_root = Join-Path $env:SystemDrive "Microsoft\AndroidNDK\"
}
$zipPath = "$env:temp\android-sdk-tools.zip"
$sdkPath = "$env:temp\android-sdk"
$licenseZipPath = "$env:temp\android-sdk-licenses.zip"

Write-Host "Downloading..."
(New-Object Net.WebClient).DownloadFile("https://dl.google.com/android/repository/sdk-tools-windows-4333796.zip", $zipPath)
if (-not (Test-Path $zipPath)) { throw "Unable to find $zipPath" }
7z x $zipPath -aoa -o"$sdkPath"
Remove-Item $zipPath -Force -ErrorAction Ignore


$base64Content = "UEsDBBQAAAAAAKJeN06amkPzKgAAACoAAAAhAAAAbGljZW5zZXMvYW5kcm9pZC1nb29nbGV0di1saWNlbnNlDQpmYzk0NmU4ZjIzMWYzZTMxNTliZjBiN2M2NTVjOTI0Y2IyZTM4MzMwUEsDBBQAAAAIAKBrN05E+YSqQwAAAFQAAAAcAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZQXByREAIQgEwP9WmYsjhxgOKJN/CNs9vmdOQ2zdRw2dxQnWjqQ/3oIgXQM9vqUiwkiX8ljWea4ZlCF3xTo1pz6w+wdQSwMEFAAAAAAAxV43TpECY7AqAAAAKgAAACQAAABsaWNlbnNlcy9hbmRyb2lkLXNkay1wcmV2aWV3LWxpY2Vuc2UNCjUwNDY2N2Y0YzBkZTdhZjFhMDZkZTlmNGIxNzI3Yjg0MzUxZjI5MTBQSwMEFAAAAAAAzF43TpOr0CgqAAAAKgAAABsAAABsaWNlbnNlcy9nb29nbGUtZ2RrLWxpY2Vuc2UNCjMzYjZhMmI2NDYwN2YxMWI3NTlmMzIwZWY5ZGZmNGFlNWM0N2Q5N2FQSwMEFAAAAAAAz143TqxN4xEqAAAAKgAAACQAAABsaWNlbnNlcy9pbnRlbC1hbmRyb2lkLWV4dHJhLWxpY2Vuc2UNCmQ5NzVmNzUxNjk4YTc3YjY2MmYxMjU0ZGRiZWVkMzkwMWU5NzZmNWFQSwMEFAAAAAAA0l43Tu2ee/8qAAAAKgAAACYAAABsaWNlbnNlcy9taXBzLWFuZHJvaWQtc3lzaW1hZ2UtbGljZW5zZQ0KNjNkNzAzZjU2OTJmZDg5MWQ1YWNhY2ZiZDhlMDlmNDBmYzk3NjEwNVBLAQIUABQAAAAAAKJeN06amkPzKgAAACoAAAAhAAAAAAAAAAEAIAAAAAAAAABsaWNlbnNlcy9hbmRyb2lkLWdvb2dsZXR2LWxpY2Vuc2VQSwECFAAUAAAACACgazdORPmEqkMAAABUAAAAHAAAAAAAAAABACAAAABpAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZVBLAQIUABQAAAAAAMVeN06RAmOwKgAAACoAAAAkAAAAAAAAAAEAIAAAAOYAAABsaWNlbnNlcy9hbmRyb2lkLXNkay1wcmV2aWV3LWxpY2Vuc2VQSwECFAAUAAAAAADMXjdOk6vQKCoAAAAqAAAAGwAAAAAAAAABACAAAABSAQAAbGljZW5zZXMvZ29vZ2xlLWdkay1saWNlbnNlUEsBAhQAFAAAAAAAz143TqxN4xEqAAAAKgAAACQAAAAAAAAAAQAgAAAAtQEAAGxpY2Vuc2VzL2ludGVsLWFuZHJvaWQtZXh0cmEtbGljZW5zZVBLAQIUABQAAAAAANJeN07tnnv/KgAAACoAAAAmAAAAAAAAAAEAIAAAACECAABsaWNlbnNlcy9taXBzLWFuZHJvaWQtc3lzaW1hZ2UtbGljZW5zZVBLBQYAAAAABgAGANoBAACPAgAAAAA="
$content = [System.Convert]::FromBase64String($base64Content)
Set-Content -Path $licenseZipPath -Value $content -Encoding Byte
7z x $licenseZipPath -aoa -o"$sdk_root"

if (Test-Path $ndk_root) {
    $androidNDKs = Get-ChildItem -Path $ndk_root | Sort-Object -Property Name -Descending | Select-Object -First 1
    $latestAndroidNDK = $androidNDKs.FullName;

    setx ANDROID_NDK_HOME $latestAndroidNDK /M
    setx ANDROID_NDK_PATH $latestAndroidNDK /M
}

setx ANDROID_HOME $sdk_root /M

Push-Location -Path $sdkPath

if ($env:INSTALL_LATEST_ONLY) {
    & '.\tools\bin\sdkmanager.bat' --sdk_root=$sdk_root `
        "platform-tools" `
        "platforms;android-30" `
        "platforms;android-29" `
        "platforms;android-28" `
        "build-tools;30.0.2" `
        "build-tools;29.0.2" `
        "build-tools;29.0.0" `
        "build-tools;28.0.3" `
        "build-tools;28.0.2" `
        "build-tools;28.0.1" `
        "build-tools;28.0.0" `
        "extras;android;m2repository" `
        "extras;google;m2repository" `
        "extras;google;google_play_services" `
        "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2" `
        "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.1" `
        "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" `
        "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1" `
        "add-ons;addon-google_apis-google-24" `
        "add-ons;addon-google_apis-google-23" `
        "add-ons;addon-google_apis-google-22" `
        "add-ons;addon-google_apis-google-21" `
        "cmake;3.6.4111459" `
        "patcher;v4" | Out-File -Width 240 -FilePath "$env:TEMP\android-sdkmanager.log"
}
else {
    & '.\tools\bin\sdkmanager.bat' --sdk_root=$sdk_root `
        "platform-tools" `
        "platforms;android-30" `
        "platforms;android-29" `
        "platforms;android-28" `
        "platforms;android-27" `
        "platforms;android-26" `
        "platforms;android-25" `
        "platforms;android-24" `
        "platforms;android-23" `
        "platforms;android-22" `
        "build-tools;30.0.2" `
        "build-tools;29.0.2" `
        "build-tools;29.0.0" `
        "build-tools;28.0.3" `
        "build-tools;28.0.2" `
        "build-tools;28.0.1" `
        "build-tools;28.0.0" `
        "build-tools;27.0.3" `
        "build-tools;27.0.2" `
        "build-tools;27.0.1" `
        "build-tools;27.0.0" `
        "build-tools;26.0.3" `
        "build-tools;26.0.2" `
        "build-tools;26.0.1" `
        "build-tools;26.0.0" `
        "build-tools;25.0.3" `
        "build-tools;25.0.2" `
        "build-tools;25.0.1" `
        "build-tools;25.0.0" `
        "build-tools;24.0.3" `
        "build-tools;24.0.2" `
        "build-tools;24.0.1" `
        "build-tools;24.0.0" `
        "build-tools;23.0.3" `
        "build-tools;23.0.2" `
        "build-tools;23.0.1" `
        "extras;android;m2repository" `
        "extras;google;m2repository" `
        "extras;google;google_play_services" `
        "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2" `
        "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.1" `
        "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" `
        "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1" `
        "add-ons;addon-google_apis-google-24" `
        "add-ons;addon-google_apis-google-23" `
        "add-ons;addon-google_apis-google-22" `
        "add-ons;addon-google_apis-google-21" `
        "cmake;3.6.4111459" `
        "patcher;v4" | Out-File -Width 240 -FilePath "$env:TEMP\android-sdkmanager.log"
}

7z a "$env:TEMP\android-sdkmanager.log.zip" "$env:TEMP\android-sdkmanager.log"

Pop-Location

Remove-Item $sdkPath -Recurse -Force -ErrorAction Ignore

$ErrorActionPreference = 'Stop'


# else {
#     & '.\tools\bin\sdkmanager.bat' --sdk_root=$sdk_root `
#         "platform-tools" `
#         "platforms;android-30" `
#         "platforms;android-29" `
#         "platforms;android-28" `
#         "platforms;android-27" `
#         "platforms;android-26" `
#         "platforms;android-25" `
#         "platforms;android-24" `
#         "platforms;android-23" `
#         "platforms;android-22" `
#         "platforms;android-21" `
#         "platforms;android-19" `
#         "build-tools;30.0.2" `
#         "build-tools;29.0.2" `
#         "build-tools;29.0.0" `
#         "build-tools;28.0.3" `
#         "build-tools;28.0.2" `
#         "build-tools;28.0.1" `
#         "build-tools;28.0.0" `
#         "build-tools;27.0.3" `
#         "build-tools;27.0.2" `
#         "build-tools;27.0.1" `
#         "build-tools;27.0.0" `
#         "build-tools;26.0.3" `
#         "build-tools;26.0.2" `
#         "build-tools;26.0.1" `
#         "build-tools;26.0.0" `
#         "build-tools;25.0.3" `
#         "build-tools;25.0.2" `
#         "build-tools;25.0.1" `
#         "build-tools;25.0.0" `
#         "build-tools;24.0.3" `
#         "build-tools;24.0.2" `
#         "build-tools;24.0.1" `
#         "build-tools;24.0.0" `
#         "build-tools;23.0.3" `
#         "build-tools;23.0.2" `
#         "build-tools;23.0.1" `
#         "build-tools;22.0.1" `
#         "build-tools;21.1.2" `
#         "build-tools;20.0.0" `
#         "build-tools;19.1.0" `
#         "extras;android;m2repository" `
#         "extras;google;m2repository" `
#         "extras;google;google_play_services" `
#         "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.2" `
#         "extras;m2repository;com;android;support;constraint;constraint-layout-solver;1.0.1" `
#         "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" `
#         "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.1" `
#         "add-ons;addon-google_apis-google-24" `
#         "add-ons;addon-google_apis-google-23" `
#         "add-ons;addon-google_apis-google-22" `
#         "add-ons;addon-google_apis-google-21" `
#         "cmake;3.6.4111459" `
#         "patcher;v4" | Out-File -Width 240 -FilePath "$env:TEMP\android-sdkmanager.log"
# }













