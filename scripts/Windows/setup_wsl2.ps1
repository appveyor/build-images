# WSL 2 and distributions
#Start-Process -FilePath "wsl" -ArgumentList "--set-default-version 2" -Wait -PassThru

#Start-Process -FilePath "wsl" -ArgumentList "--update" -Wait -PassThru

#Start-Sleep -s 10
wsl --install -d Ubuntu-20.04 --no-launch
ubuntu2004 install --root
#wsl --install -d Ubuntu-20.04 --no-launch
#Start-Process -FilePath "wsl" -ArgumentList "--install -d Ubuntu-22.04 --no-launch" -Wait -PassThru
#Start-Sleep -s 10
#wsl --install -d Ubuntu-22.04 --no-launch
#Start-Sleep -s 10


Start-Sleep -s 10

wsl -l -v

# Ubuntu 20.04
# ============

wsl -d Ubuntu-20.04 -u root adduser --gecos GECOS --disabled-password appveyor

#$ubuntuExe = "C:\WSL\Ubuntu2004\ubuntu.exe"
#. $ubuntuExe install --root
#. $ubuntuExe run adduser appveyor --gecos `"First,Last,RoomNumber,WorkPhone,HomePhone`" --disabled-password
wsl -d Ubuntu-20.04 -- echo 'appveyor:Password12!' `| sudo chpasswd
wsl -d Ubuntu-20.04 -- usermod -aG sudo appveyor
wsl -d Ubuntu-20.04 -- echo -e `"appveyor\tALL=`(ALL`)\tNOPASSWD: ALL`" `| sudo tee -a /etc/sudoers.d/appveyor
#wsl -d Ubuntu-20.04 -- echo -e `"appveyor\tALL=`(ALL`)\tNOPASSWD: ALL`" > /etc/sudoers.d/appveyor
wsl -d Ubuntu-20.04 -- chmod 0755 /etc/sudoers.d/appveyor
wsl -d Ubuntu-20.04 -- sudo echo “[user]” `| sudo tee -a /etc/wsl.conf
wsl -d Ubuntu-20.04 -- sudo echo “default=appveyor” `| sudo tee -a /etc/wsl.conf
wsl -d Ubuntu-20.04 -- sudo apt-get update

. $ubuntuExe run sudo apt-get update


# Ubuntu 22.04
# ============

Write-warning "Installing Ubuntu 22.04 for WSL"




# Testing WSL
# ===========

# wslconfig /setdefault ubuntu-16.04
# wsl lsb_release -a

# wslconfig /setdefault ubuntu-18.04
# wsl lsb_release -a

# wslconfig /setdefault ubuntu
# wsl lsb_release -a

# Rename C:\Windows\System32\bash.exe to avoid conflicts with default Git's bash
# ===========

# takeown /F "$env:SystemRoot\System32\bash.exe"
# icacls "$env:SystemRoot\System32\bash.exe" /grant administrators:F
# ren "$env:SystemRoot\System32\bash.exe" wsl-bash.exe