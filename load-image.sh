#!/bin/bash
SETTINGS=settings.conf
USER=$(cat $SETTINGS | grep USER= | awk -F'=' '{print $2}')
GET_ISO=$(cat $SETTINGS | grep IMAGE= | awk -F'=' '{print $2}')
CUSTOM_IMAGE_FOLDER=$(cat $SETTINGS | grep FOLDER= | awk -F'=' '{print $2}')
IMAGE=$(echo $GET_ISO | sed 's/.*.iso-cd\///')
MBR_TEMPLATE=$(cat $SETTINGS | grep MBR_TEMPLATE= | awk -F'=' '{print $2}')
EFI_IMG=$(cat $SETTINGS | grep EFI_IMG= | awk -F'=' '{print $2}')
echo "Loading latest image ...";

if [[ $(id -u) -ne 0 ]]; then 
echo "Please run as root or using sudo";exit 2 
fi

if [[ -f $IMAGE ]]; then rm -r $IMAGE; fi
wget $GET_ISO >> /dev/null
if [[ -d $CUSTOM_IMAGE_FOLDER ]]; then rm -rf $CUSTOM_IMAGE_FOLDER/; fi

echo "Image downloaded ...";
# Create new custom image
mkdir -p $CUSTOM_IMAGE_FOLDER
# Unpack original image
mkdir -p /tmp/$CUSTOM_IMAGE_FOLDER

echo "Copying ..."
bsdtar -C $CUSTOM_IMAGE_FOLDER/ -xf $IMAGE
chmod -R +w $CUSTOM_IMAGE_FOLDER/
chown -R $USER.$USER ../

echo "Extracting EFI partition image ..."

start_block=$(/sbin/fdisk -l "$IMAGE" | fgrep "$IMAGE"2 | awk '{print $2}')
block_count=$(/sbin/fdisk -l "$IMAGE" | fgrep "$IMAGE"2 | awk '{print $4}')
if test "$start_block" -gt 0 -a "$block_count" -gt 0 2>/dev/null
then
 dd if=$IMAGE bs=512 skip=$start_block count=$block_count of=$EFI_IMG
else
 echo "Cannot read plausible start block and block count from fdisk" >&2
 part_img_ready=0
fi

echo "Creating MBR template (enable booting from USB stick via legacy BIOS) ..."
# Extract MBR template (first 432 bytes) file to disk
dd if=$IMAGE bs=1 count=432 of=$MBR_TEMPLATE
chown $USER.$USER $MBR_TEMPLATE

echo "Complete.";exit 0 
umount $IMAGE
