#
# The list of VS 2019 components: https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-community?vs-2019&view=vs-2019
#

Function InstallVS
{
  Param
  (
    [String]$WorkLoads,
    [String]$Sku,
    [String] $VSBootstrapperURL
  )

  $exitCode = -1

  try
  {
    Write-Host "Downloading Bootstrapper ..."
    Invoke-WebRequest -Uri $VSBootstrapperURL -OutFile "${env:Temp}\vs_$Sku.exe"

    $FilePath = "${env:Temp}\vs_$Sku.exe"
    $Arguments = ('/c', $FilePath, $WorkLoads, '--quiet', '--norestart', '--wait', '--nocache' )

    Write-Host "Starting Install ..."
    $process = Start-Process -FilePath cmd.exe -ArgumentList $Arguments -Wait -PassThru
    $exitCode = $process.ExitCode

    if ($exitCode -eq 0 -or $exitCode -eq 3010)
    {
      Write-Host -Object 'Installation successful'
      return $exitCode
    }
    else
    {
      Write-Host -Object "Non zero exit code returned by the installation process : $exitCode."

      # this wont work because of log size limitation in extension manager
      # Get-Content $customLogFilePath | Write-Host

      exit $exitCode
    }
  }
  catch
  {
    Write-Host -Object "Failed to install Visual Studio. Check the logs for details in $customLogFilePath"
    Write-Host -Object $_.Exception.Message
    exit -1
  }
}

$WorkLoads = '--add Microsoft.VisualStudio.Workload.ManagedDesktop ' + `
		'--add Microsoft.VisualStudio.Workload.NativeDesktop ' + `
		'--add Microsoft.VisualStudio.Workload.Universal ' + `
		'--add Microsoft.VisualStudio.Workload.NetWeb ' + `
		'--add Microsoft.VisualStudio.Workload.Azure ' + `
		'--add Microsoft.VisualStudio.Workload.Data ' + `
		'--add Microsoft.VisualStudio.Workload.Office ' + `
		'--add Microsoft.VisualStudio.Workload.NetCrossPlat ' + `
		'--add Microsoft.VisualStudio.Workload.VisualStudioExtension ' + `
		'--add Microsoft.VisualStudio.Workload.NetCoreTools ' + `
		'--add microsoft.net.componentgroup.targetingpacks.common ' + `
		'--add microsoft.visualstudio.component.entityframework ' + `
		'--add microsoft.visualstudio.component.debugger.justintime ' + `
		'--add microsoft.visualstudio.component.fsharp.desktop ' + `
		'--add microsoft.net.componentgroup.4.6.2.developertools ' + `
		'--add microsoft.net.componentgroup.4.7.2.developertools ' + `
		'--add microsoft.visualstudio.component.vc.diagnostictools ' + `
		'--add microsoft.visualstudio.component.vc.cmake.project ' + `
		'--add microsoft.visualstudio.component.vc.atl ' + `
		'--add microsoft.visualstudio.component.vc.testadapterforboosttest ' + `
		'--add microsoft.visualstudio.component.vc.testadapterforgoogletest ' + `
		'--add microsoft.component.vc.runtime.ucrtsdk ' + `
		'--add Microsoft.VisualStudio.Component.Windows10SDK.16299 ' + `
		'--add Microsoft.VisualStudio.Component.Windows10SDK.17134 ' + `
		'--add Microsoft.VisualStudio.Component.Windows10SDK.17763 ' + `
		'--add Microsoft.VisualStudio.Component.Windows10SDK.18362 ' + `
		'--add microsoft.visualstudio.component.vc.140 ' + `
		'--add microsoft.visualstudio.componentgroup.web.cloudtools ' + `
		'--add microsoft.visualstudio.component.aspnet45 ' + `
		'--add microsoft.visualstudio.component.webdeploy ' + `
		'--add microsoft.netcore.componentgroup.web ' + `
		'--add microsoft.component.azure.datalake.tools ' + `
		'--add microsoft.visualstudio.componentgroup.azure.resourcemanager.tools ' + `
		'--add microsoft.visualstudio.componentgroup.azure.cloudservices ' + `
		'--add microsoft.visualstudio.component.azure.mobileappssdk ' + `
		'--add microsoft.visualstudio.component.azure.servicefabric.tools ' + `
		'--add microsoft.visualstudio.component.teamoffice ' + `
		'--add microsoft.visualstudio.component.winxp ' + `
		'--add microsoft.visualstudio.component.vc.llvm.clang ' + `
		'--add microsoft.visualstudio.component.vc.llvm.clangtoolset ' + `
		'--add microsoft.visualstudio.component.vc.atlmfc ' + `
		'--add microsoft.visualstudio.component.vc.tools.arm64 ' + `
		'--add microsoft.visualstudio.component.vc.tools.arm ' + `
		'--add microsoft.visualstudio.component.vc.atl.spectre ' + `
		'--add microsoft.visualstudio.component.vc.atl.arm.spectre ' + `
		'--add microsoft.visualstudio.component.vc.atl.arm64.spectre ' + `
		'--add microsoft.visualstudio.component.vc.runtimes.arm.spectre ' + `
		'--add microsoft.visualstudio.component.vc.runtimes.arm64.spectre ' + `
		'--add microsoft.visualstudio.component.vc.runtimes.x86.x64.spectre ' + `
		'--add microsoft.visualstudio.component.vc.atl.arm ' + `
		'--add microsoft.visualstudio.component.vc.atl.arm64 ' + `
		'--add microsoft.visualstudio.component.vc.14.20.x86.x64 ' + `
		'--add microsoft.visualstudio.component.vc.atlmfc.spectre ' + `
		'--add microsoft.visualstudio.component.vc.mfc.arm.spectre ' + `
		'--add microsoft.visualstudio.component.vc.mfc.arm64.spectre ' + `
		'--add microsoft.visualstudio.component.vc.mfc.arm ' + `
		'--add microsoft.visualstudio.component.vc.mfc.arm64 ' + `
		'--add microsoft.visualstudio.component.vc.14.21.arm ' + `
		'--add microsoft.visualstudio.component.vc.14.21.arm64 ' + `
		'--add microsoft.visualstudio.component.vc.14.21.x86.x64 ' + `
		'--add microsoft.visualstudio.component.vc.14.21.arm.spectre ' + `
		'--add microsoft.visualstudio.component.vc.14.21.arm64.spectre ' + `
		'--add microsoft.visualstudio.component.vc.14.21.x86.x64.spectre ' + `
		'--add microsoft.visualstudio.component.portablelibrary ' + `
		'--add component.android.sdk25.private ' + `
		'--add component.android.ndk.r16b ' + `
		'--add component.ant ' + `
		'--add component.mdd.android ' + `
		'--add microsoft.visualstudio.workload.nativemobile '

$Sku = 'Community'
$VSBootstrapperURL = 'https://aka.ms/vs/16/release/vs_community.exe'

$ErrorActionPreference = 'Stop'

# Install VS
$exitCode = InstallVS -WorkLoads $WorkLoads -Sku $Sku -VSBootstrapperURL $VSBootstrapperURL

if (get-Service SQLWriterw -ErrorAction Ignore) {
  Stop-Service SQLWriter
  Set-Service SQLWriter -StartupType Manual
}
if (get-Service IpOverUsbSvc -ErrorAction Ignore) {
  Stop-Service IpOverUsbSvc
  Set-Service IpOverUsbSvc -StartupType Manual
}

Write-Host "Adding Visual Studio 2019 current MSBuild to PATH..." -ForegroundColor Cyan
Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin"
Add-Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\150"
