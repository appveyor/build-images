Write-Host "Pre-compiling .NET assemblies, this can take a 15-20 minutes..." -ForegroundColor Cyan
& $env:windir\Microsoft.NET\Framework64\v4.0.30319\ngen update /force | Out-Null
Write-Host "Pre-compilation completed" -ForegroundColor Green