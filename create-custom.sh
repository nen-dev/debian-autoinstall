#!/bin/bash
SETTINGS=settings.conf

GET_ISO=$(cat $SETTINGS | grep IMAGE= | awk -F'=' '{print $2}')
IMAGENAME=$(cat $SETTINGS | grep NAMEIMG= | awk -F'=' '{print $2}')
CUSTOM_IMAGE_FOLDER=$(cat $SETTINGS | grep FOLDER= | awk -F'=' '{print $2}')
MBR_TEMPLATE=$(cat $SETTINGS | grep MBR_TEMPLATE= | awk -F'=' '{print $2}')
EFI_IMG=$(cat $SETTINGS | grep EFI_IMG= | awk -F'=' '{print $2}')

echo "Building custom iso image..."
echo "Calculating MD5 ..."
rm $CUSTOM_IMAGE_FOLDER/md5sum.txt
(cd $CUSTOM_IMAGE_FOLDER/ && find . -type f -print0 | xargs -0 md5sum | grep -v "boot.cat" | grep -v "md5sum.txt" > md5sum.txt)
XISO='/usr/bin/xorriso'
if [ ! -x $XISO ]; then
    echo "Please install xorriso using: apt-get install -y xorriso";exit 2;
fi
if [[ -f $IMAGENAME.iso ]]; then rm $IMAGENAME.iso; fi
xorriso -as mkisofs \
   -r -V "Debian $IMAGENAME" \
   -o $IMAGENAME.iso \
   -J -J -joliet-long -cache-inodes \
   -isohybrid-mbr $MBR_TEMPLATE \
   -b isolinux/isolinux.bin \
   -c isolinux/boot.cat \
   -boot-load-size 4 -boot-info-table -no-emul-boot \
   -eltorito-alt-boot \
   -e boot/grub/efi.img \
   -no-emul-boot -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
   $CUSTOM_IMAGE_FOLDER/
#genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
#            -no-emul-boot -boot-load-size 4 -boot-info-table \
#            -o $IMAGENAME.iso $CUSTOM_IMAGE_FOLDER/

#isohybrid $IMAGENAME-*.iso
if [[ $? -ne 0 ]]; then 
    echo 'Something went wrong';exit 2 
fi    
echo "Complete.";exit 0 
