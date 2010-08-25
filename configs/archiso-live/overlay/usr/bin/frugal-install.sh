#!/bin/bash

. /usr/lib/liblinuxlive
DEVICE=${1} # ex. /dev/sda1
DEVICE_NAME=${DEVICE##*/} # ex. sda1
DEVICE_BASE=${DEVICE_NAME%[0-9]} # ex. sda
CDNAME=$(cmdline_value cdname)
GRUB=/boot/grub

if [ -d /mnt/live/mnt/findiso ]; then
    LIVEFOLDER="$(dirname $(find /mnt/live/mnt/findiso -name packages.list ))" # ex. sr0 or tmp or findiso
elif [ -d /mnt/live/mnt/tmp ]; then
    LIVEFOLDER="$(dirname $(find /mnt/live/mnt/tmp -name packages.list ))"
else
    LIVEFOLDER="$(dirname $(find /mnt/live/mnt -name packages.list ))"
fi

ISO=${2}

if [ "${DEVICE}" = "" ]; then
	echo "help:"
	echo "	ex. ${0} /dev/sda1"
	echo "	ex. ${0} /dev/sda1 name-of-cdimage.iso"
	exit 1	
elif [ ! "$(ls ${DEVICE})" ]; then
	echo "${DEVICE} doesn't exist."
	exit 1
fi

if [ ! -d /mnt/${DEVICE_NAME} ]; then
	mkdir -p /mnt/${DEVICE_NAME}
fi

if [ "$(cat /proc/mounts | grep ${DEVICE})" ]; then
	echo "${DEVICE} mounted already."
else
	mount ${DEVICE} /mnt/${DEVICE_NAME}
fi

if [ ! -d /mnt/${DEVICE_NAME}/boot/grub ]; then
	grub-install --recheck --root-directory=/mnt/${DEVICE_NAME} /dev/${DEVICE_BASE}
fi

#if [ -d /usr/lib/grub/i386-pc ]; then
#	cp -af /usr/lib/grub/i386-pc/* /mnt/${DEVICE_NAME}/boot/grub
#fi

mkdir -p /mnt/${DEVICE_NAME}/changes
mkdir -p /mnt/${DEVICE_NAME}/modules

if [ "${ISO}" != "" ]; then
	if [ -f ${ISO} ]; then
		cp -af ${ISO} /mnt/${DEVICE_NAME}/
		cat <<EOF>>/mnt/${DEVICE_NAME}/boot/grub/grub.cfg
set default=0
set timeout=30
menuentry "ISO +changes +modpath" {
search --set -f "/ISO"
loopback loop "/ISO"
linux (loop)/boot/vmlinuz findiso=/ISO elevator=deadline locale=en_US.UTF-8 keymap=us session=xfce load=overlay usbdelay=5 changes=DEVICE/changes modpath=modules
initrd (loop)/boot/initrd.img
}

menuentry "ISO +changes" {
search --set -f "/ISO"
loopback loop "/ISO"
linux (loop)/boot/vmlinuz findiso=/ISO elevator=deadline locale=en_US.UTF-8 keymap=us session=xfce load=overlay usbdelay=5 changes=DEVICE/changes
initrd (loop)/boot/initrd.img
}

menuentry "ISO failsafe" {
search --set -f "/ISO"
loopback loop "/ISO"
linux (loop)/boot/vmlinuz findiso=/ISO elevator=deadline locale=en_US.UTF-8 keymap=us session=xfce load=overlay nohd usbdelay=5
initrd (loop)/boot/initrd.img
}
EOF
		sed -i "s|ISO|${ISO##*/}|g" /mnt/${DEVICE_NAME}/boot/grub/grub.cfg
		sed -i "s|DEVICE|${DEVICE}|g" /mnt/${DEVICE_NAME}/boot/grub/grub.cfg

	fi
elif [ -d ${LIVEFOLDER} ]; then

	if [ ${CDNAME} != "" ]; then
		LIVECDNAME=${CDNAME}
        fi

	mkdir -p /mnt/${DEVICE_NAME}/${LIVECDNAME}
	cp -af ${LIVEFOLDER}/* /mnt/${DEVICE_NAME}/${LIVECDNAME}
	if [ -f /mnt/${DEVICE_NAME}/boot/grub/grub.cfg ]; then
		mv -f /mnt/${DEVICE_NAME}/boot/grub/grub.cfg /mnt/${DEVICE_NAME}/boot/grub/grub.cfg.old
	fi

		cat <<EOF>>/mnt/${DEVICE_NAME}/boot/grub/grub.cfg
set default=0
set timeout=30
menuentry "LIVECDNAME +changes +modpath" {
linux /LIVECDNAME/boot/vmlinuz from=DEVICE/LIVECDNAME elevator=deadline locale=en_US.UTF-8 keymap=us session=xfce load=overlay usbdelay=5 changes=DEVICE/changes modpath=modules
initrd /LIVECDNAME/boot/initrd.img
}

menuentry "LIVECDNAME +changes" {
linux /LIVECDNAME/boot/vmlinuz from=DEVICE/LIVECDNAME elevator=deadline locale=en_US.UTF-8 keymap=us session=xfce load=overlay changes=DEVICE/changes
initrd /LIVECDNAME/boot/initrd.img
}

menuentry "LIVECDNAME failsafe" {
linux /LIVECDNAME/boot/vmlinuz from=DEVICE/LIVECDNAME elevator=deadline locale=en_US.UTF-8 keymap=us session=xfce load=overlay nohd usbdelay=5
initrd /LIVECDNAME/boot/initrd.img
}
EOF
	sed -i "s|LIVECDNAME|${LIVECDNAME}|g" /mnt/${DEVICE_NAME}/boot/grub/grub.cfg
	sed -i "s|DEVICE|${DEVICE}|g" /mnt/${DEVICE_NAME}/boot/grub/grub.cfg

fi