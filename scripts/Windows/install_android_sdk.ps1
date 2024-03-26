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
#(New-Object Net.WebClient).DownloadFile("https://dl.google.com/android/repository/commandlinetools-win-10406996_latest.zip", $zipPath)
if (-not (Test-Path $zipPath)) { throw "Unable to find $zipPath" }
7z x $zipPath -aoa -o"$sdkPath"
Remove-Item $zipPath -Force -ErrorAction Ignore


$base64Content = "UEsDBBQAAAAAAKJeN06amkPzKgAAACoAAAAhAAAAbGljZW5zZXMvYW5kcm9pZC1nb29nbGV0di1saWNlbnNlDQpmYzk0NmU4ZjIzMWYzZTMxNTliZjBiN2M2NTVjOTI0Y2IyZTM4MzMwUEsDBBQAAAAIAKBrN05E+YSqQwAAAFQAAAAcAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZQXByREAIQgEwP9WmYsjhxgOKJN/CNs9vmdOQ2zdRw2dxQnWjqQ/3oIgXQM9vqUiwkiX8ljWea4ZlCF3xTo1pz6w+wdQSwMEFAAAAAAAxV43TpECY7AqAAAAKgAAACQAAABsaWNlbnNlcy9hbmRyb2lkLXNkay1wcmV2aWV3LWxpY2Vuc2UNCjUwNDY2N2Y0YzBkZTdhZjFhMDZkZTlmNGIxNzI3Yjg0MzUxZjI5MTBQSwMEFAAAAAAAzF43TpOr0CgqAAAAKgAAABsAAABsaWNlbnNlcy9nb29nbGUtZ2RrLWxpY2Vuc2UNCjMzYjZhMmI2NDYwN2YxMWI3NTlmMzIwZWY5ZGZmNGFlNWM0N2Q5N2FQSwMEFAAAAAAAz143TqxN4xEqAAAAKgAAACQAAABsaWNlbnNlcy9pbnRlbC1hbmRyb2lkLWV4dHJhLWxpY2Vuc2UNCmQ5NzVmNzUxNjk4YTc3YjY2MmYxMjU0ZGRiZWVkMzkwMWU5NzZmNWFQSwMEFAAAAAAA0l43Tu2ee/8qAAAAKgAAACYAAABsaWNlbnNlcy9taXBzLWFuZHJvaWQtc3lzaW1hZ2UtbGljZW5zZQ0KNjNkNzAzZjU2OTJmZDg5MWQ1YWNhY2ZiZDhlMDlmNDBmYzk3NjEwNVBLAQIUABQAAAAAAKJeN06amkPzKgAAACoAAAAhAAAAAAAAAAEAIAAAAAAAAABsaWNlbnNlcy9hbmRyb2lkLWdvb2dsZXR2LWxpY2Vuc2VQSwECFAAUAAAACACgazdORPmEqkMAAABUAAAAHAAAAAAAAAABACAAAABpAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZVBLAQIUABQAAAAAAMVeN06RAmOwKgAAACoAAAAkAAAAAAAAAAEAIAAAAOYAAABsaWNlbnNlcy9hbmRyb2lkLXNkay1wcmV2aWV3LWxpY2Vuc2VQSwECFAAUAAAAAADMXjdOk6vQKCoAAAAqAAAAGwAAAAAAAAABACAAAABSAQAAbGljZW5zZXMvZ29vZ2xlLWdkay1saWNlbnNlUEsBAhQAFAAAAAAAz143TqxN4xEqAAAAKgAAACQAAAAAAAAAAQAgAAAAtQEAAGxpY2Vuc2VzL2ludGVsLWFuZHJvaWQtZXh0cmEtbGljZW5zZVBLAQIUABQAAAAAANJeN07tnnv/KgAAACoAAAAmAAAAAAAAAAEAIAAAACECAABsaWNlbnNlcy9taXBzLWFuZHJvaWQtc3lzaW1hZ2UtbGljZW5zZVBLBQYAAAAABgAGANoBAACPAgAAAAA="
#$base64Content = "UEsDBBQAAAAAAKyhe1cAAAAAAAAAAAAAAAAJAAAAbGljZW5zZXMvUEsDBAoAAAAAAKqhe1e7n0IrKgAAACoAAAAhAAAAbGljZW5zZXMvYW5kcm9pZC1nb29nbGV0di1saWNlbnNlDQo2MDEwODViOTRjZDc3ZjBiNTRmZjg2NDA2OTU3MDk5ZWJlNzljNGQ2UEsDBAoAAAAAAKuhe1fzQumJKgAAACoAAAAkAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlDQo4NTlmMzE3Njk2ZjY3ZWYzZDdmMzBhNTBhNTU2MGU3ODM0YjQzOTAzUEsDBAoAAAAAAHiee1cKSOJFKgAAACoAAAAcAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZQ0KMjQzMzNmOGE2M2I2ODI1ZWE5YzU1MTRmODNjMjgyOWIwMDRkMWZlZVBLAwQKAAAAAACroXtXec1a4SoAAAAqAAAAJAAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLXByZXZpZXctbGljZW5zZQ0KODQ4MzFiOTQwOTY0NmE5MThlMzA1NzNiYWI0YzljOTEzNDZkOGFiZFBLAwQKAAAAAACroXtXk6vQKCoAAAAqAAAAGwAAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQ0KMzNiNmEyYjY0NjA3ZjExYjc1OWYzMjBlZjlkZmY0YWU1YzQ3ZDk3YVBLAwQKAAAAAACsoXtXrE3jESoAAAAqAAAAJAAAAGxpY2Vuc2VzL2ludGVsLWFuZHJvaWQtZXh0cmEtbGljZW5zZQ0KZDk3NWY3NTE2OThhNzdiNjYyZjEyNTRkZGJlZWQzOTAxZTk3NmY1YVBLAwQKAAAAAACsoXtXkb1vWioAAAAqAAAAJgAAAGxpY2Vuc2VzL21pcHMtYW5kcm9pZC1zeXNpbWFnZS1saWNlbnNlDQplOWFjYWI1YjVmYmI1NjBhNzJjZmFlY2NlODk0Njg5NmZmNmFhYjlkUEsBAj8AFAAAAAAArKF7VwAAAAAAAAAAAAAAAAkAJAAAAAAAAAAQAAAAAAAAAGxpY2Vuc2VzLwoAIAAAAAAAAQAYAGUvajqxIdoBAAAAAAAAAAAAAAAAAAAAAFBLAQI/AAoAAAAAAKqhe1e7n0IrKgAAACoAAAAhACQAAAAAAAAAIAAAACcAAABsaWNlbnNlcy9hbmRyb2lkLWdvb2dsZXR2LWxpY2Vuc2UKACAAAAAAAAEAGABAfTc4sSHaAQAAAAAAAAAAAAAAAAAAAABQSwECPwAKAAAAAACroXtX80LpiSoAAAAqAAAAJAAkAAAAAAAAACAAAACQAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlCgAgAAAAAAABABgA5oW/OLEh2gEAAAAAAAAAAAAAAAAAAAAAUEsBAj8ACgAAAAAAeJ57VwpI4kUqAAAAKgAAABwAJAAAAAAAAAAgAAAA/AAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLWxpY2Vuc2UKACAAAAAAAAEAGABgOvQ1riHaAQAAAAAAAAAAAAAAAAAAAABQSwECPwAKAAAAAACroXtXec1a4SoAAAAqAAAAJAAkAAAAAAAAACAAAABgAQAAbGljZW5zZXMvYW5kcm9pZC1zZGstcHJldmlldy1saWNlbnNlCgAgAAAAAAABABgAshwiObEh2gEAAAAAAAAAAAAAAAAAAAAAUEsBAj8ACgAAAAAAq6F7V5Or0CgqAAAAKgAAABsAJAAAAAAAAAAgAAAAzAEAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQoAIAAAAAAAAQAYAK9iljmxIdoBAAAAAAAAAAAAAAAAAAAAAFBLAQI/AAoAAAAAAKyhe1esTeMRKgAAACoAAAAkACQAAAAAAAAAIAAAAC8CAABsaWNlbnNlcy9pbnRlbC1hbmRyb2lkLWV4dHJhLWxpY2Vuc2UKACAAAAAAAAEAGADB/v85sSHaAQAAAAAAAAAAAAAAAAAAAABQSwECPwAKAAAAAACsoXtXkb1vWioAAAAqAAAAJgAkAAAAAAAAACAAAACbAgAAbGljZW5zZXMvbWlwcy1hbmRyb2lkLXN5c2ltYWdlLWxpY2Vuc2UKACAAAAAAAAEAGAA522o6sSHaAQAAAAAAAAAAAAAAAAAAAABQSwUGAAAAAAgACACDAwAACQMAAAAA"
#$base64Content = "UEsDBBQAAAAAAKNK11IAAAAAAAAAAAAAAAAJAAAAbGljZW5zZXMvUEsDBAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhAAAAbGljZW5zZXMvYW5kcm9pZC1nb29nbGV0di1saWNlbnNlDQo2MDEwODViOTRjZDc3ZjBiNTRmZjg2NDA2OTU3MDk5ZWJlNzljNGQ2UEsDBAoAAAAAAKBK11LzQumJKgAAACoAAAAkAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlDQo4NTlmMzE3Njk2ZjY3ZWYzZDdmMzBhNTBhNTU2MGU3ODM0YjQzOTAzUEsDBAoAAAAAAKFK11IKSOJFKgAAACoAAAAcAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstbGljZW5zZQ0KMjQzMzNmOGE2M2I2ODI1ZWE5YzU1MTRmODNjMjgyOWIwMDRkMWZlZVBLAwQKAAAAAACiStdSec1a4SoAAAAqAAAAJAAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLXByZXZpZXctbGljZW5zZQ0KODQ4MzFiOTQwOTY0NmE5MThlMzA1NzNiYWI0YzljOTEzNDZkOGFiZFBLAwQKAAAAAACiStdSk6vQKCoAAAAqAAAAGwAAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQ0KMzNiNmEyYjY0NjA3ZjExYjc1OWYzMjBlZjlkZmY0YWU1YzQ3ZDk3YVBLAwQKAAAAAACiStdSrE3jESoAAAAqAAAAJAAAAGxpY2Vuc2VzL2ludGVsLWFuZHJvaWQtZXh0cmEtbGljZW5zZQ0KZDk3NWY3NTE2OThhNzdiNjYyZjEyNTRkZGJlZWQzOTAxZTk3NmY1YVBLAwQKAAAAAACjStdSkb1vWioAAAAqAAAAJgAAAGxpY2Vuc2VzL21pcHMtYW5kcm9pZC1zeXNpbWFnZS1saWNlbnNlDQplOWFjYWI1YjVmYmI1NjBhNzJjZmFlY2NlODk0Njg5NmZmNmFhYjlkUEsBAj8AFAAAAAAAo0rXUgAAAAAAAAAAAAAAAAkAJAAAAAAAAAAQAAAAAAAAAGxpY2Vuc2VzLwoAIAAAAAAAAQAYACIHOBcRaNcBIgc4FxFo1wHBTVQTEWjXAVBLAQI/AAoAAAAAAJ1K11K7n0IrKgAAACoAAAAhACQAAAAAAAAAIAAAACcAAABsaWNlbnNlcy9hbmRyb2lkLWdvb2dsZXR2LWxpY2Vuc2UKACAAAAAAAAEAGACUEFUTEWjXAZQQVRMRaNcB6XRUExFo1wFQSwECPwAKAAAAAACgStdS80LpiSoAAAAqAAAAJAAkAAAAAAAAACAAAACQAAAAbGljZW5zZXMvYW5kcm9pZC1zZGstYXJtLWRidC1saWNlbnNlCgAgAAAAAAABABgAsEM0FBFo1wGwQzQUEWjXAXb1MxQRaNcBUEsBAj8ACgAAAAAAoUrXUgpI4kUqAAAAKgAAABwAJAAAAAAAAAAgAAAA/AAAAGxpY2Vuc2VzL2FuZHJvaWQtc2RrLWxpY2Vuc2UKACAAAAAAAAEAGAAsMGUVEWjXASwwZRURaNcB5whlFRFo1wFQSwECPwAKAAAAAACiStdSec1a4SoAAAAqAAAAJAAkAAAAAAAAACAAAABgAQAAbGljZW5zZXMvYW5kcm9pZC1zZGstcHJldmlldy1saWNlbnNlCgAgAAAAAAABABgA7s3WFRFo1wHuzdYVEWjXAfGm1hURaNcBUEsBAj8ACgAAAAAAokrXUpOr0CgqAAAAKgAAABsAJAAAAAAAAAAgAAAAzAEAAGxpY2Vuc2VzL2dvb2dsZS1nZGstbGljZW5zZQoAIAAAAAAAAQAYAGRDRxYRaNcBZENHFhFo1wFfHEcWEWjXAVBLAQI/AAoAAAAAAKJK11KsTeMRKgAAACoAAAAkACQAAAAAAAAAIAAAAC8CAABsaWNlbnNlcy9pbnRlbC1hbmRyb2lkLWV4dHJhLWxpY2Vuc2UKACAAAAAAAAEAGADGsq0WEWjXAcayrRYRaNcBxrKtFhFo1wFQSwECPwAKAAAAAACjStdSkb1vWioAAAAqAAAAJgAkAAAAAAAAACAAAACbAgAAbGljZW5zZXMvbWlwcy1hbmRyb2lkLXN5c2ltYWdlLWxpY2Vuc2UKACAAAAAAAAEAGAA4LjgXEWjXATguOBcRaNcBIgc4FxFo1wFQSwUGAAAAAAgACACDAwAACQMAAAAA"
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
    & '.\cmdline-tools\bin\sdkmanager.bat' --sdk_root=$sdk_root `
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
    & '.\cmdline-tools\bin\sdkmanager.bat' --sdk_root=$sdk_root `
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
        "platforms;android-21" `
        "platforms;android-19" `
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
        "build-tools;22.0.1" `
        "build-tools;21.1.2" `
        "build-tools;20.0.0" `
        "build-tools;19.1.0" `
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
        "cmake;3.6.4111459" | Out-File -Width 240 -FilePath "$env:TEMP\android-sdkmanager.log"
}

7z a "$env:TEMP\android-sdkmanager.log.zip" "$env:TEMP\android-sdkmanager.log"

Pop-Location

Remove-Item $sdkPath -Recurse -Force -ErrorAction Ignore
# Resset JAVA_HOME variable and path
#[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Progra~1\Java\jdk1.8.0", "machine")
#$env:JAVA_HOME="C:\Progra~1\Java\jdk1.8.0"

$ErrorActionPreference = 'Stop'
















