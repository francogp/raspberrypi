#!/bin/bash

#
# Copyright (c) 2022. Cooperativa Eléctrica de Venado Tuerto. Autor: Pellegrini Franco Gastón
#

# /home/franco/Programas/wineX86.sh

sudo dpkg --add-architecture i386

# box64 installation
echo '* Backup any old wine installations'
cd ~ || exit 100
git clone https://github.com/ptitSeb/box64 || exit 100
cd box64 || exit 100
mkdir build; cd build; cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo || exit 100
make -j4 || exit 100
sudo make install || exit 100
# If it's the first install, you also need:

sudo systemctl restart systemd-binfmt || exit 100

# Backup any old wine installations
echo '* Backup any old wine installations'
sudo rm -r ~/wine ~/wine-old
sudo rm -r ~/.wine ~/.wine-old
sudo rm -r /usr/local/bin/wine64 /usr/local/bin/wine64-old
sudo rm -r /usr/local/bin/wineboot /usr/local/bin/wineboot-old
sudo rm -r /usr/local/bin/winecfg /usr/local/bin/winecfg-old
sudo rm -r /usr/local/bin/wineserver /usr/local/bin/wineserver-old

# Download, extract wine, and install wine
# (Replace the links/versions below with links/versions from the WineHQ site for the version of wine you wish to install. Note that we need the i386 version for Box86 even though we're installing it on our ARM processor.)
# (Pick an i386 version of wine-devel, wine-staging, or wine-stable)
prefix=wine-stable
version=7.0.0.0
downloadFolder=Descargas
architecture=amd64
echo '* Download, extract wine, and install wine'
cd ~/${downloadFolder} || exit 100
wget https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-${architecture}/${prefix}-${architecture}_${version}~buster-1_${architecture}.deb || exit 100 # NOTE: Replace this link with the version you want
wget https://dl.winehq.org/wine-builds/debian/dists/buster/main/binary-${architecture}/${prefix}_${version}~buster-1_${architecture}.deb || exit 100  # NOTE: Also replace this link with the version you want

dpkg-deb -xv ${prefix}-${architecture}_${version}~buster-1_${architecture}.deb wine-installer || exit 100 # NOTE: Make sure these dpkg command matches the filename of the deb package you just downloaded
dpkg-deb -xv ${prefix}_${version}~buster-1_${architecture}.deb wine-installer || exit 100

mv ~/${downloadFolder}/wine-installer/opt/wine* ~/wine || exit 100
rm wine*.deb # clean up
rm -rf wine-installer # clean up

# Install shortcuts (make 32bit launcher & symlinks. Credits: grayduck, Botspot)
#echo '* Install shortcuts (make 32bit launcher & symlinks. Credits: grayduck, Botspot)'
#echo -e '#!/bin/bash\nsetarch linux32 -L '"$HOME/wine/bin/wine "'"$@"' | sudo tee -a /usr/local/bin/wine >/dev/null # Create a script to launch wine programs as 32bit only
sudo rm /usr/local/bin/wine
sudo ln -fs ~/wine/bin/wine64 /usr/local/bin/wine64 # You could aslo just make a symlink, but box86 only works for 32bit apps at the moment
sudo ln -fs ~/wine/bin/wineboot /usr/local/bin/wineboot
sudo ln -fs ~/wine/bin/winecfg /usr/local/bin/winecfg
sudo ln -fs ~/wine/bin/wineserver /usr/local/bin/wineserver
sudo chmod +x /usr/local/bin/wine64 /usr/local/bin/wineboot /usr/local/bin/winecfg /usr/local/bin/wineserver || exit 100

# These packages are needed for running wine-staging on RPi 4 (Credits: chills340)
echo '* These packages are needed for running wine-staging on RPi 4 (Credits: chills340)'
sudo apt install libstb0 -y || exit 100
cd ~/${downloadFolder}
wget -r -l1 -np -nd -A "libfaudio0_*~bpo10+1_${architecture}.deb" http://ftp.us.debian.org/debian/pool/main/f/faudio/ || exit 100 # Download libfaudio i386 no matter its version number
dpkg-deb -xv libfaudio0_*~bpo10+1_${architecture}.deb libfaudio || exit 100
sudo cp -TRv libfaudio/usr/ /usr/ || exit 100
rm libfaudio0_*~bpo10+1_${architecture}.deb || exit 100 # clean up
rm -rf libfaudio # clean up

#install windows fonts
sudo apt-get install -y libfreetype6 ttf-mscorefonts-installer || exit 100

# Boot wine (make fresh wineprefix in ~/.wine )
echo '* Boot wine (make fresh wineprefix in ~/.wine )'
wine64 wineboot || exit 100

#sudo apt install wine wine-binfmt q4wine winbind 


# # Installing winetricks
# sudo apt-get install cabextract -y                                                                   # winetricks needs this installed
# sudo mv /usr/local/bin/winetricks /usr/local/bin/winetricks-old                                      # Backup old winetricks
# cd ~/${downloadFolder} && wget https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks || exit 100 # Download
# sudo chmod +x winetricks && sudo mv winetricks /usr/bin/   
# BOX86_NOBANNER=1 winetricks -q corefonts vcrun2010 dotnet20sp1
