#!/bin/bash

######################################
# Author: LiangJC
# Version: 1.2
# Date: 2021-09-22
# Note: Building N1 kernel 5.xx.xxx 
######################################

STIME=`date`
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
LINUX="linux-5.4.y"
OUTPUT="output"
ROOTFS="/opt/bullseye-rootfs"
MOUNT_ARM64="/opt/ch-mount.sh"
export ARCH="arm64"
export CROSS_COMPILE="/opt/aarch64-linux-gnu/bin/aarch64-linux-gnu-"

#help info
if [ $1 == "-h" -o $1 == "help" ];then
	echo "Usage: $0 [clang | gcc] "
	echo ""
	echo "	$0			save kernel archive(Complete the compilation first)"
	echo "	$0 clang		make clang"
	echo "	$0 gcc			make gcc"
	exit 2
fi	

#build
cd $LINUX
if [ -n $1 ];then
	if [ "$1" == "clang" ];then
		CC=/opt/clang/bin/clang
		LD=/opt/clang/bin/ld.lld
		make -j$(nproc) CC=$CC LD=$LD
	elif [ "$1" == "gcc" ];then
		make -j$(nproc)	
	fi
fi

#modules
KERNAME=`cat include/config/kernel.release`
KERVER=`echo $KERNAME | cut -d. -f1`
PATCHLEVEL=`echo $KERNAME | cut -d. -f2`
sudo rm -rf ../$OUTPUT/{boot,dtb,modules}
sudo mkdir -p ../$OUTPUT/{boot,dtb,modules}
sudo make modules_install INSTALL_MOD_PATH=/opt
sudo mv "/opt/lib/modules/$KERNAME" ../$OUTPUT/modules/
cd "../$OUTPUT/modules/$KERNAME"
sudo rm -rf build source
sudo find . -name "*.ko" -exec ln -s {} \;
cd -

#copy file
sudo cp arch/arm64/boot/dts/amlogic/*.dtb ../$OUTPUT/dtb/
sudo cp .config ../$OUTPUT/boot/config-$KERNAME
sudo cp System.map ../$OUTPUT/boot/System.map-$KERNAME
sudo cp arch/arm64/boot/Image ../$OUTPUT/boot/zImage-$KERNAME
sudo rm -rf $ROOTFS/boot/*
sudo rm -rf $ROOTFS/lib/modules/$KERVER.$PATCHLEVEL.*
sudo cp -r ../$OUTPUT/modules/$KERNAME $ROOTFS/lib/modules/

#build initrd
/usr/bin/expect <<EOF
set timeout 300
spawn $MOUNT_ARM64 -m $ROOTFS/
expect "root@" { send "cp /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime\n" }
expect "root@" { send "mkinitramfs -k -c xz -o /boot/initrd.img-$KERNAME $KERNAME\n" }
expect "root@" { send "mkimage -A arm64 -O linux -T ramdisk -C none -a 0 -e 0 -n uInitrd -d /boot/initrd.img-$KERNAME /boot/uInitrd-$KERNAME\n" }
expect "root@" { send "exit\n" }
expect eof
EOF
$MOUNT_ARM64 -u $ROOTFS/
sudo cp $ROOTFS/boot/{initrd.img-$KERNAME,uInitrd-$KERNAME} ../$OUTPUT/boot/
sudo chown -R root:root ../$OUTPUT

#package
cd ../$OUTPUT/boot
sudo tar -zcf ../boot-$KERNAME.tar.gz .
cd ../dtb
sudo tar -zcf ../dtb-$KERNAME.tar.gz .
cd ../modules
sudo tar -zcf ../modules-$KERNAME.tar.gz .
cd ..
sudo rm -rf boot dtb modules
sudo rm -rf $ROOTFS/boot/*
sudo rm -rf $ROOTFS/lib/modules/$KERVER.$PATCHLEVEL.*

#echo info
echo ""
echo "Build kernel is finish"
echo "Version: $KERNAME"
echo "Start: $STIME"
echo "End: "`date`
echo ""
