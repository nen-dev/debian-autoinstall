#!/bin/bash
SETTINGS=settings.conf
IMAGENAME=$(cat $SETTINGS | grep NAMEIMG= | awk -F'=' '{print $2}')
echo "Making bootable usb ..."
if [[ $(id -u) -ne 0 ]]; then 
echo "Please run as root or using sudo.";exit 2 
fi
USBDEV=$1
if [ -z "$USBDEV" ]; then
    echo -e "You should specify the usb device path.\n\tExample: make-bootable-usb.sh /dev/sdb";exit 2 
fi
hdparm -r0 $USBDEV
dd if=$IMAGENAME.iso of=$USBDEV bs=4M; sync
# Uncomment this if you want burn CD 
# this is suitable if you have very old PC|Server
# xorriso -as cdrecord -v dev=/dev/sr0 -dao class-cisco-iso.iso
echo "Complete.";exit 0 
