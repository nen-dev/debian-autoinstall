# debian-autoinstall

Scripts for creating custom Debian autoinstall image:

   run.sh              | main script which runs all scripts and make new custom image   
   prereq              | you should install packages which are listed in this file before using scripts
   settings.conf       | contains parameters to build your own Debian custom installation image 
   pressed.cfg         | contains default autoinstall pressed file, you could specify additional setting in it if you need
                         ATTENTION: account settings will add using customize-image.sh
   _SCRIPTS/            | folder which contain scripts to configure your OS after installation
                         you could add all what you need to start by _SCRIPTS/postinstall.sh
                         SCRIPTS/postinstall.sh - run all additional scripts in _SCRIPTS folder
   load-image.sh       | download latest image and unpack it in folder which you specify in settings.conf
   customize-image.sh  | contains commands for Debian image customization
   create-custom.sh    | create new images $IMAGE-mbr.iso,  $IMAGE-efi.iso, $IMAGE.iso
   mk-bootable-usb.sh  | you could use this script to create bootable USB
   
   
