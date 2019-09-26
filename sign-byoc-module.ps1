$psFiles = (Get-ChildItem Connect-*).FullName
$psFiles += (Get-ChildItem AppVeyorBYOC-*).FullName
$psFiles += (Get-ChildItem appveyor-byoc-psm\*).FullName
Set-AuthenticodeSignature -FilePath $psFiles @(Get-ChildItem Cert:\CurrentUser\My -CodeSign)[0]