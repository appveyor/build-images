Write-Host "Installing JRuby 9.0.0.0..." -ForegroundColor Cyan

Write-Host "Downloading..."
$zipPath = "$env:TEMP\jruby-bin-9.0.0.0.zip"
(New-Object Net.WebClient).DownloadFile('https://s3.amazonaws.com/jruby.org/downloads/9.0.0.0/jruby-bin-9.0.0.0.zip', $zipPath)
Write-Host "Unpacking..."
7z x $zipPath -oC:\ | Out-Null
del $zipPath

[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Progra~1\Java\jdk1.8.0", "machine")
$env:JAVA_HOME="C:\Progra~1\Java\jdk1.8.0"

$cmd = "$env:TEMP\jruby.cmd"
"C:\jruby-9.0.0.0\bin\jruby --version" | Out-File $cmd -Encoding ascii; & $cmd

# install bundler
#$gemPath = "$env:TEMP\bundler-1.10.6.gem"
#(New-Object Net.WebClient).DownloadFile('https://rubygems.org/downloads/bundler-1.10.6.gem', $gemPath)

#"C:\jruby-9.0.0.0\bin\gem install --local $gemPath" | Out-File $cmd -Encoding ascii; & $cmd
"C:\jruby-9.0.0.0\bin\gem install bundler" | Out-File $cmd -Encoding ascii; & $cmd
"C:\jruby-9.0.0.0\bin\gem list --local" | Out-File $cmd -Encoding ascii; & $cmd
del $cmd
#del $gemPath

Write-Host "Installed JRuby 9.0.0.0" -ForegroundColor Green