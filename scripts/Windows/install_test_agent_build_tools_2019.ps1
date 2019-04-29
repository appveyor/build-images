Invoke-WebRequest -UseBasicParsing https://download.visualstudio.microsoft.com/download/pr/446c5efe-9162-41a1-b380-704c82d13afa/8c6c6f404ed99e477007f16a336f99a6/vs_testagent.exe -OutFile vs_TestAgent.exe; `
Start-Process vs_TestAgent.exe -ArgumentList '--quiet', '--norestart', '--nocache' -NoNewWindow -Wait; `
Remove-Item -Force vs_TestAgent.exe -ErrorAction Ignore; `
Invoke-WebRequest -UseBasicParsing https://download.visualstudio.microsoft.com/download/pr/df649173-11e9-4af2-8eb7-0eb02ba8958a/cadb5bdac41e55bb8f6a6b7c45273370/vs_buildtools.exe -OutFile vs_BuildTools.exe; `
setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1; `
Start-Process vs_BuildTools.exe `
-ArgumentList `
'--add', 'Microsoft.VisualStudio.Workload.MSBuildTools', `
'--add', 'Microsoft.VisualStudio.Workload.NetCoreBuildTools', `
'--add', 'Microsoft.Component.ClickOnce.MSBuild', `
'--quiet', '--norestart', '--nocache' `
-NoNewWindow -Wait; `
Remove-Item -Force vs_buildtools.exe -ErrorAction Ignore; `
Remove-Item -Force -Recurse "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\" -ErrorAction Ignore; `
Remove-Item -Force -Recurse ${Env:TEMP}\* -ErrorAction Ignore; `
Remove-Item -Force -Recurse "${Env:ProgramData}\Package Cache\ -ErrorAction Ignore"

Add-SessionPath "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\"
Add-SessionPath "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\"

Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\"
Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin\"