echo 'export PATH=\"$PATH:/usr/local/bin\"' >> $HOME/.bashrc
echo '{{ user `install_password` }}' | sudo systemsetup -setcomputersleep Never
echo '{{ user `install_password` }}' | CI=1 /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)\"
/usr/local/bin/brew install --cask powershell
/usr/local/bin/brew install coreutils zlib p7zip

brew install appveyor/brew/appveyor-build-agent
brew services restart appveyor/brew/appveyor-build-agent