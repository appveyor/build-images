Get-ChildItem C:\custom-scripts | ? {
  $_.name.EndsWith(".ps1", [System.StringComparison]::OrdinalIgnoreCase)
} | % {& "C:\custom-scripts\$($_.name)"}
Remove-Item -Path C:\custom-scripts -ErrorAction Ignore -Force -Recurse