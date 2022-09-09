# debian-autoinstall

Scripts for creating custom Debian autoinstall image or debian usb bootable flash:

file                | description
-----------------------|---------------------------------------------------
_run.sh_              | main script which runs all scripts and makes new custom image
_prereq_             | you should install packages which are listed in this file before using scripts
_settings.conf_       | contains parameters to build your own Debian custom installation image 
_pressed.cfg_         | contains default autoinstall pressed file, you may specify additional settings in it if you need **ATTENTION:** account settings will be added using customize-image.sh
__SCRIPTS/_            | folder which contain scripts to configure your OS after installation; you could add all what you need to start by __SCRIPTS/postinstall.sh_; _SCRIPTS/postinstall.sh_ - run all additional scripts in _SCRIPTS folder
_load-image.sh_      | download latest image and unpack it in folder which you specify in settings.conf
_customize-image.sh_  | contains commands for Debian image customization
_create-custom.sh_    | create new images $IMAGE-mbr.iso,  $IMAGE-efi.iso, $IMAGE.iso
_mk-bootable-usb.sh_  | you could use this script to create bootable USB
 
 # How to start use it?
 1) Modify settings.conf
 2) You can modify file pressed.cfg 
 modify 345 tasksel tasksel/first multiselect standard line
 change 
 tasksel/first multiselect standard - for console server
 or 
 tasksel tasksel/first multiselect standard, desktop, lxde-desktop - for workstation
 3) Run the following:
 ```console
 apt-get -y install bsdtar xorriso
 
 git clone git@github.com:nen-dev/debian-autoinstall.git
 
 bash run.sh 

 # /dev/sdb - usb disk
 
 bash mk-bootable-usb.sh /dev/sdb
 ```
