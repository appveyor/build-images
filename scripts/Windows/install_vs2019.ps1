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
		'--add microsoft.visualstudio.component.windows81sdk ' + `
		'--add microsoft.visualstudio.component.windows10sdk.17134 ' + `
		'--add microsoft.visualstudio.componentgroup.windows10sdk.16299 ' + `
		'--add microsoft.visualstudio.componentgroup.windows10sdk.15063 ' + `
		'--add microsoft.visualstudio.component.windows10sdk.14393 ' + `
		'--add microsoft.visualstudio.component.windows10sdk.10586 ' + `
		'--add microsoft.visualstudio.component.windows10sdk.10240 ' + `
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
		'--add microsoft.visualStudio.component.vc.llvm.clang ' + `
		'--add microsoft.visualStudio.component.vc.ATLMFC ' + `
		'--add component.android.sdk27 '

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
