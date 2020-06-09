#!/bin/bash
# You are now in directory /root
# place here whatever you want to run for changing new OS

# 1. Setup APT

CODENAME='buster'
PACKAGES_LIST="python3 python3-pip zabbix-agent openssh-server telnet qemu-guest-agent open-vm-tools"
WORKDIR='/root/_SCRIPTS/'
echo -e "
# $CODENAME
deb http://deb.debian.org/debian/ $CODENAME main contrib non-free
deb http://security.debian.org/debian-security $CODENAME/updates main contrib non-free

# $CODENAME-updates, previously known as 'volatile'
deb http://deb.debian.org/debian/ $CODENAME-updates main contrib non-free
" > /etc/apt/sources.list

printf 'Package: *\nPin: release a=testing\nPin-Priority: 90\n' > /etc/apt/preferences.d/limit-testing
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 80\n' > /etc/apt/preferences.d/limit-sid
printf "Package: *\nPin: release a=$CODENAME\nPin-Priority: 750\n" > /etc/apt/preferences.d/priority-$CODENAME


apt-get clean
apt-get update
apt-cache policy apt-transport-https
apt-get -y install apt-transport-https

echo -e "
# $CODENAME
deb https://deb.debian.org/debian/ $CODENAME main contrib non-free
deb http://security.debian.org/debian-security $CODENAME/updates main contrib non-free

# $CODENAME-updates, previously known as 'volatile'
deb https://deb.debian.org/debian/ $CODENAME-updates main contrib non-free

# TESTING
deb https://deb.debian.org/debian/ testing main contrib non-free
# Sid
deb https://deb.debian.org/debian/ sid main contrib non-free
# SOURCES
#deb-src https://deb.debian.org/debian/ testing main contrib non-free 
#deb-src https://deb.debian.org/debian/ stretch main contrib non-free
#deb-src https://security.debian.org/debian-security stretch/updates main contrib non-free
#deb-src https://deb.debian.org/debian/ stretch-updates main contrib non-free
#deb-src https://deb.debian.org/debian/ stable main contrib non-free
#deb-src https://security.debian.org/debian-security stable/updates main contrib non-free
#deb-src https://deb.debian.org/debian/ stable-updates main contrib non-free

" > /etc/apt/sources.list
# 2. Zabbix agent install
wget https://repo.zabbix.com/zabbix/4.4/debian/pool/main/z/zabbix-release/zabbix-release_4.4-1+buster_all.deb
apt-get update 

# Packages install
for package in $PACKAGES_LIST
do
    apt-cache policy $package
    apt-get -y install $package 2>> $WORKDIR/install.log
done

systemctl enable zabbix-agent 

exit 0
