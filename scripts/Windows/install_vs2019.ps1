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
    $Arguments = ($WorkLoads, '--quiet', '--norestart', '--wait', '--nocache')

    Write-Host "Starting Install ..."
    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru
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

$WorkLoads = '--add Component.Android.NDK.R16B ' + `
	'--add Component.Android.SDK25.Private ' + `
	'--add Component.Android.SDK28 ' + `
	'--add Component.MDD.Android ' + `
	'--add Component.Microsoft.VisualStudio.RazorExtension ' + `
	'--add Component.Microsoft.VisualStudio.Web.AzureFunctions ' + `
	'--add Component.Microsoft.Web.LibraryManager ' + `
	'--add Component.OpenJDK ' + `
	'--add Component.Xamarin ' + `
	'--add Component.Xamarin.RemotedSimulator ' + `
	'--add Microsoft.Component.Azure.DataLake.Tools ' + `
	'--add Microsoft.Component.MSBuild ' + `
	'--add Microsoft.Component.NetFX.Native ' + `
	'--add Microsoft.Component.VC.Runtime.UCRTSDK ' + `
	'--add Microsoft.ComponentGroup.Blend ' + `
	'--add Microsoft.Net.Component.4.5.1.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.5.2.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.5.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.6.1.SDK ' + `
	'--add Microsoft.Net.Component.4.6.1.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.6.2.SDK ' + `
	'--add Microsoft.Net.Component.4.6.2.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.6.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.7.1.SDK ' + `
	'--add Microsoft.Net.Component.4.7.1.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.7.2.SDK ' + `
	'--add Microsoft.Net.Component.4.7.2.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.7.SDK ' + `
	'--add Microsoft.Net.Component.4.7.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.8.SDK ' + `
	'--add Microsoft.Net.Component.4.8.TargetingPack ' + `
	'--add Microsoft.Net.Component.4.TargetingPack ' + `
	'--add Microsoft.Net.ComponentGroup.4.6.2.DeveloperTools ' + `
	'--add Microsoft.Net.ComponentGroup.DevelopmentPrerequisites ' + `
	'--add Microsoft.Net.ComponentGroup.TargetingPacks.Common ' + `
	'--add Microsoft.NetCore.Component.DevelopmentTools ' + `
	'--add Microsoft.NetCore.Component.SDK ' + `
	'--add Microsoft.NetCore.Component.Web ' + `
	'--add Microsoft.VisualStudio.Component.AppInsights.Tools ' + `
	'--add Microsoft.VisualStudio.Component.AspNet45 ' + `
	'--add Microsoft.VisualStudio.Component.Azure.AuthoringTools ' + `
	'--add Microsoft.VisualStudio.Component.Azure.ClientLibs ' + `
	'--add Microsoft.VisualStudio.Component.Azure.Compute.Emulator ' + `
	'--add Microsoft.VisualStudio.Component.Azure.ResourceManager.Tools ' + `
	'--add Microsoft.VisualStudio.Component.Azure.ServiceFabric.Tools ' + `
	'--add Microsoft.VisualStudio.Component.Azure.Storage.Emulator ' + `
	'--add Microsoft.VisualStudio.Component.Azure.Waverton ' + `
	'--add Microsoft.VisualStudio.Component.Azure.Waverton.BuildTools ' + `
	'--add Microsoft.VisualStudio.Component.CloudExplorer ' + `
	'--add Microsoft.VisualStudio.Component.Common.Azure.Tools ' + `
	'--add Microsoft.VisualStudio.Component.CoreEditor ' + `
	'--add Microsoft.VisualStudio.Component.Debugger.JustInTime ' + `
	'--add Microsoft.VisualStudio.Component.DiagnosticTools ' + `
	'--add Microsoft.VisualStudio.Component.DockerTools ' + `
	'--add Microsoft.VisualStudio.Component.EntityFramework ' + `
	'--add Microsoft.VisualStudio.Component.FSharp ' + `
	'--add Microsoft.VisualStudio.Component.FSharp.Desktop ' + `
	'--add Microsoft.VisualStudio.Component.FSharp.WebTemplates ' + `
	'--add Microsoft.VisualStudio.Component.Graphics ' + `
	'--add Microsoft.VisualStudio.Component.Graphics.Tools ' + `
	'--add Microsoft.VisualStudio.Component.IISExpress ' + `
	'--add Microsoft.VisualStudio.Component.IntelliCode ' + `
	'--add Microsoft.VisualStudio.Component.JavaScript.Diagnostics ' + `
	'--add Microsoft.VisualStudio.Component.JavaScript.TypeScript ' + `
	'--add Microsoft.VisualStudio.Component.ManagedDesktop.Core ' + `
	'--add Microsoft.VisualStudio.Component.ManagedDesktop.Prerequisites ' + `
	'--add Microsoft.VisualStudio.Component.Merq ' + `
	'--add Microsoft.VisualStudio.Component.MonoDebugger ' + `
	'--add Microsoft.VisualStudio.Component.MSODBC.SQL ' + `
	'--add Microsoft.VisualStudio.Component.MSSQL.CMDLnUtils ' + `
	'--add Microsoft.VisualStudio.Component.NuGet ' + `
	'--add Microsoft.VisualStudio.Component.PortableLibrary ' + `
	'--add Microsoft.VisualStudio.Component.Roslyn.Compiler ' + `
	'--add Microsoft.VisualStudio.Component.Roslyn.LanguageServices ' + `
	'--add Microsoft.VisualStudio.Component.Sharepoint.Tools ' + `
	'--add Microsoft.VisualStudio.Component.SQL.ADAL ' + `
	'--add Microsoft.VisualStudio.Component.SQL.CLR ' + `
	'--add Microsoft.VisualStudio.Component.SQL.DataSources ' + `
	'--add Microsoft.VisualStudio.Component.SQL.LocalDB.Runtime ' + `
	'--add Microsoft.VisualStudio.Component.SQL.SSDT ' + `
	'--add Microsoft.VisualStudio.Component.TeamOffice ' + `
	'--add Microsoft.VisualStudio.Component.TextTemplating ' + `
	'--add Microsoft.VisualStudio.Component.TypeScript.3.6 ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.20.ATL ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.20.ATL.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.20.CLI.Support ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.20.MFC ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.20.MFC.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.20.x86.x64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.20.x86.x64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.ARM ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.ARM.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.ARM64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.ARM64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.ATL ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.ATL.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.CLI.Support ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.MFC ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.MFC.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.x86.x64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.21.x86.x64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.ATL ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.ATL.ARM ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.ATL.ARM.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.ATL.ARM64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.ATL.ARM64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.ATL.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.CLI.Support ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.MFC ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.MFC.ARM ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.MFC.ARM.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.MFC.ARM64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.MFC.ARM64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.MFC.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.x86.x64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.14.22.x86.x64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.140 ' + `
	'--add Microsoft.VisualStudio.Component.VC.ATL ' + `
	'--add Microsoft.VisualStudio.Component.VC.ATL.ARM ' + `
	'--add Microsoft.VisualStudio.Component.VC.ATL.ARM.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.ATL.ARM64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.ATL.ARM64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.ATL.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.ATLMFC ' + `
	'--add Microsoft.VisualStudio.Component.VC.ATLMFC.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.CLI.Support ' + `
	'--add Microsoft.VisualStudio.Component.VC.CMake.Project ' + `
	'--add Microsoft.VisualStudio.Component.VC.CoreIde ' + `
	'--add Microsoft.VisualStudio.Component.VC.DiagnosticTools ' + `
	'--add Microsoft.VisualStudio.Component.VC.Llvm.Clang ' + `
	'--add Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset ' + `
	'--add Microsoft.VisualStudio.Component.VC.MFC.ARM ' + `
	'--add Microsoft.VisualStudio.Component.VC.MFC.ARM.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.MFC.ARM64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.MFC.ARM64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.Redist.14.Latest ' + `
	'--add Microsoft.VisualStudio.Component.VC.Runtimes.ARM.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.Runtimes.ARM64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.TestAdapterForBoostTest ' + `
	'--add Microsoft.VisualStudio.Component.VC.TestAdapterForGoogleTest ' + `
	'--add Microsoft.VisualStudio.Component.VC.Tools.ARM ' + `
	'--add Microsoft.VisualStudio.Component.VC.Tools.ARM64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.v141.ATL ' + `
	'--add Microsoft.VisualStudio.Component.VC.v141.ATL.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.v141.CLI.Support ' + `
	'--add Microsoft.VisualStudio.Component.VC.v141.MFC ' + `
	'--add Microsoft.VisualStudio.Component.VC.v141.MFC.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VC.v141.x86.x64 ' + `
	'--add Microsoft.VisualStudio.Component.VC.v141.x86.x64.Spectre ' + `
	'--add Microsoft.VisualStudio.Component.VSSDK ' + `
	'--add Microsoft.VisualStudio.Component.Wcf.Tooling ' + `
	'--add Microsoft.VisualStudio.Component.Web ' + `
	'--add Microsoft.VisualStudio.Component.WebDeploy ' + `
	'--add Microsoft.VisualStudio.Component.Windows10SDK.16299 ' + `
	'--add Microsoft.VisualStudio.Component.Windows10SDK.17134 ' + `
	'--add Microsoft.VisualStudio.Component.Windows10SDK.17763 ' + `
	'--add Microsoft.VisualStudio.Component.Windows10SDK.18362 ' + `
	'--add Microsoft.VisualStudio.Component.WinXP ' + `
	'--add Microsoft.VisualStudio.Component.Workflow ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.Azure.CloudServices ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.Azure.Prerequisites ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.Azure.ResourceManager.Tools ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.AzureFunctions ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.MSIX.Packaging ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.UWP.NetCoreAndStandard ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.UWP.Support ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.UWP.Xamarin ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.VisualStudioExtension.Prerequisites ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.Web ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.Web.CloudTools ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.CMake ' + `
	'--add Microsoft.VisualStudio.ComponentGroup.WebToolsExtensions.TemplateEngine ' + `
	'--add Microsoft.VisualStudio.Workload.Azure ' + `
	'--add Microsoft.VisualStudio.Workload.CoreEditor ' + `
	'--add Microsoft.VisualStudio.Workload.Data ' + `
	'--add Microsoft.VisualStudio.Workload.ManagedDesktop ' + `
	'--add Microsoft.VisualStudio.Workload.NativeDesktop ' + `
	'--add Microsoft.VisualStudio.Workload.NativeMobile ' + `
	'--add Microsoft.VisualStudio.Workload.NetCoreTools ' + `
	'--add Microsoft.VisualStudio.Workload.NetCrossPlat ' + `
	'--add Microsoft.VisualStudio.Workload.NetWeb ' + `
	'--add Microsoft.VisualStudio.Workload.Office ' + `
	'--add Microsoft.VisualStudio.Workload.Universal ' + `
	'--add Microsoft.VisualStudio.Workload.VisualStudioExtension '

$Sku = 'Community'

if ($env:install_vs2019_preview) {
	Write-Host "Installing from 'Preview' channel"
	$VSBootstrapperURL = 'https://aka.ms/vs/16/pre/vs_community.exe'
} else {
	Write-Host "Installing from 'Release' channel"
	$VSBootstrapperURL = 'https://aka.ms/vs/16/release/vs_community.exe'
}

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

$vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community"
if (-not (Test-Path $vsPath)) {
    $vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Preview"
}

Add-Path "$vsPath\MSBuild\Current\Bin"
Add-Path "$vsPath\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\150"
