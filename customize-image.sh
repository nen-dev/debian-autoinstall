#!/bin/bash
SETTINGS=settings.conf
CUSTOM_IMAGE_FOLDER=$(cat $SETTINGS | grep FOLDER= | awk -F'=' '{print $2}')
NAMEOFINSTALLATION=$(cat $SETTINGS | grep INSTALLNAME= | awk -F'=' '{print $2}')
USERNAME=$(cat $SETTINGS | grep USERNAME= | awk -F'=' '{print $2}')
USERPASS=$(cat $SETTINGS | grep USERPASS= | awk -F'=' '{print $2}')
ROOTPASS=$(cat $SETTINGS | grep ROOTPASS= | awk -F'=' '{print $2}')

echo "Configuring custom image ..."
echo "if loadfont \$prefix/font.pf2 ; then
  set gfxmode=800x600
  set gfxpayload=keep
  insmod efi_gop
  insmod efi_uga
  insmod video_bochs
  insmod video_cirrus
  insmod gfxterm
  insmod png
  terminal_output gfxterm
fi

if background_image /isolinux/splash.png; then
  set color_normal=light-gray/black
  set color_highlight=white/black
elif background_image /splash.png; then
  set color_normal=light-gray/black
  set color_highlight=white/black
else
  set menu_color_normal=cyan/blue
  set menu_color_highlight=white/blue
fi

insmod play
play 960 440 1 0 4 440 1
set theme=/boot/grub/theme/1
menuentry '$NAMEOFINSTALLATION' {
  set background_color=black

  linux  /install.amd/vmlinuz file=/cdrom/preseed.cfg debian-installer/locale=ru_RU.UTF-8 console-setup/layoutcode=ru quiet ---
  initrd   /install.amd/initrd.gz
}


" > $CUSTOM_IMAGE_FOLDER/boot/grub/grub.cfg
echo "
label install
    menu label ^Install
    kernel /install.amd/vmlinuz
    append vga=788 initrd=/install.amd/initrd.gz --- quiet 

label autoinstall
    menu label ^Autoinstall  $NAMEOFINSTALLATION
    kernel /install.amd/vmlinuz
    append vga=788 initrd=/install.amd/initrd.gz priority=high locale=en_GB.UTF-8 keymap=gb file=/cdrom/preseed.cfg --- quiet 
" > $CUSTOM_IMAGE_FOLDER/isolinux/txt.cfg

cp preseed.cfg $CUSTOM_IMAGE_FOLDER/

USERPASSMD5=$(echo "$USERPASS" | mkpasswd -s -m sha-512)
ROOTPASSMD5=$(echo "$ROOTPASS" | mkpasswd -s -m sha-512)

while echo $USERPASSMD5|grep -q '*' || echo $USERPASSMD5|grep -q '/' || echo $USERPASSMD5|grep -q '\\'; do USERPASSMD5=$(echo "$USERPASS" | mkpasswd -s -m sha-512); done
while echo $ROOTPASSMD5|grep -q '*' || echo $ROOTPASSMD5|grep -q '/' || echo $ROOTPASSMD5|grep -q '\\'; do ROOTPASSMD5=$(echo "$ROOTPASS" | mkpasswd -s -m sha-512); done
#sed -i "s/### Account setup/### Account setup\nd-i passwd\/root-login boolean true\nd-i passwd\/make-user boolean true\nd-i passwd\/root-password-crypted password $USERPASSMD5\nd-i passwd\/user-fullname string $USERNAME\nd-i passwd\/username string $USERNAME\nd-i passwd\/user-password-crypted password $ROOTPASSMD5\nd-i user-setup\/allow-password-weak boolean true\nd-i user-setup\/encrypt-home boolean false\n/" $CUSTOM_IMAGE_FOLDER/preseed.cfg

sed -i "s/### Account setup/### Account setup\nd-i passwd\/root-login boolean true\nd-i passwd\/make-user boolean true\nd-i passwd\/root-password password $ROOTPASS\n\nd-i passwd\/root-password-again password $ROOTPASS\nd-i passwd\/user-fullname string $USERNAME\nd-i passwd\/username string $USERNAME\nd-i passwd\/user-password password $USERPASS\n\nd-i passwd\/user-password-again password $USERPASS\nd-i user-setup\/allow-password-weak boolean true\nd-i user-setup\/encrypt-home boolean false\n/" $CUSTOM_IMAGE_FOLDER/preseed.cfg

 
cp -r _SCRIPTS/  $CUSTOM_IMAGE_FOLDER/
echo "Complete.";exit 0 

