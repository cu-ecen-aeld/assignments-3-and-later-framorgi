#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=/home/framorgi/arm-x-compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-

echo "-----------------------"
echo "--- MANUAL_LINUX.SH ---"
if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
	echo "-----------------------"
	echo "--- CLONE REPO DONE ---"
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "-------------------------"
    echo "--- CHECK OUT VERSION ---"
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}
    echo "-----------------------"
    echo "--- CHECK OUT DONE ---"

    # TODO: Add your kernel build steps here
    
    echo "-------------------"
    echo "--- KERNEL MAKE ---"
    echo "KERNEL MAKE mrproper:  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper"
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
    echo "--- KERNEL mrproper DONE ---"
    echo "-------------------"
    echo "KERNEL MAKE defconfig:  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig"
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    echo "--- KERNEL defconfig DONE ---"
    echo "-------------------"
    echo "KERNEL MAKE all:  make -j4 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all"
    make -j4 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all
    echo "--- KERNEL all DONE ---"
    echo "-------------------"
fi

echo "---------------"
echo "--- ROOT FS ---"
echo "Adding the Image in outdir"
cp "${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image" "${OUTDIR}/Image"
echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi


echo "------------------------"
echo "--- CREATING ROOT FS ---"
mkdir -p "$OUTDIR/rootfs"
cd "$OUTDIR/rootfs"
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin var/log
echo "---------------------------"
echo "--- ROOT FS TREE CREATED---"

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
    echo "--------------------"
    echo "--- BUSYBOX CLONE---"
    git clone git://busybox.net/busybox.git
    echo "--------------------------"
    echo "--- BUSYBOX CLONE DONE ---"
    cd busybox
    echo "-----------------------------"
    echo "--- BUSYBOX REPO CHECKOUT ---"
    git checkout ${BUSYBOX_VERSION}
    echo "----------------------------------"
    echo "--- BUSYBOX REPO CHECKOUT DONE ---"
    
    echo "---------------------"
    echo "--- BUSYBOX CONFIG---"
    # TODO:  Configure busybox
    
    echo "----------------------------------------"
    echo "--- BUSYBOX distclean: make distclean---"
    make distclean
    echo "------------------------------"
    echo "--- BUSYBOX distclean: DONE---"
    
    
    echo "----------------------------------------"
    echo "--- BUSYBOX defconfig: make defconfig---"
    make defconfig
    echo "------------------------------"
    echo "--- BUSYBOX defconfig: DONE---"
else
    cd busybox
fi

# TODO: Make and install busybox

echo "--------------------"
echo "--- BUSYBOX MAKE ---"


echo "BUSYBOX MAKE :  make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE "
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
echo "--- BUSYBOX MAKE DONE ---"
echo "-------------------------"


echo "BUSYBOX INSTALL:  make CONFIG_PREFIX=$OUTDIR/rootfs ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE install"
make CONFIG_PREFIX="$OUTDIR/rootfs" ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE install

echo "--- BUSYBOX INSTALL DONE ---"
echo "----------------------------"


echo "------------------------"
echo "--- LIB DEPENDENCIES ---"
cd "$OUTDIR/rootfs"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
echo "sysroot is ${SYSROOT}"

cp "$SYSROOT/lib/ld-linux-aarch64.so.1" "$OUTDIR/rootfs/lib/ld-linux-aarch64.so.1"
cp "$SYSROOT/lib64/libm.so.6" "$OUTDIR/rootfs/lib64/libm.so.6"
cp "$SYSROOT/lib64/libresolv.so.2" "$OUTDIR/rootfs/lib64/libresolv.so.2"
cp "$SYSROOT/lib64/libc.so.6" "$OUTDIR/rootfs/lib64/libc.so.6"

# TODO: Make device nodes

echo "----------------------------------"
echo "--- MKNOD DEVICE NODE CREATION ---"

echo "MKNOD STEP: sudo mknod -m 666 $OUTDIR/rootfs/dev/null c 1 3"
sudo mknod -m 666 "$OUTDIR/rootfs/dev/null" c 1 3
echo "MKNOD STEP DONE"

echo "MKNOD STEP: sudo mknod -m 600 $OUTDIR/rootfs/dev/console c 1 3"
sudo mknod -m 600 "$OUTDIR/rootfs/dev/console" c 5 1
echo "MKNOD STEP DONE"

# TODO: Clean and build the writer utility
echo "----------------------------"
echo "--- BUILD WRITER UTILITY ---"
cd "$FINDER_APP_DIR"

make clean
echo "clean DONE"
make CROSS_COMPILE=$CROSS_COMPILE
echo "make CROSS_COMPILE=$CROSS_COMPILE DONE"
# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "------------------------------"
echo "--- MOVING FILES TO ROOTFS ---"
cp writer finder.sh finder-test.sh "$OUTDIR/rootfs/home"
mkdir -p "$OUTDIR/rootfs/home/conf"
cp conf/username.txt conf/assignment.txt "$OUTDIR/rootfs/home/conf"
cp autorun-qemu.sh "$OUTDIR/rootfs/home"
echo "FILES MOVED"

# TODO: Chown the root directory
echo "----------------------"
echo "--- CHOWN ROOT DIR ---"
sudo chown -R root:root "$OUTDIR/rootfs"
# TODO: Create initramfs.cpio.gz

echo "---------------------------------------------"
echo "--- CREATE FILESYSTEM RAM IMAGE CPIO FILE ---"
cd "$OUTDIR/rootfs"

echo "---STEP find . | cpio -H newc -ov --owner root:root >$OUTDIR/rootfs/initramfs.cpio"
find . | cpio -H newc -ov --owner root:root >"$OUTDIR/rootfs/initramfs.cpio"
echo "---CPIO FILE CREATED"


echo "---STEP gzip -f $OUTDIR/rootfs/initramfs.cpio"
gzip -f "$OUTDIR/rootfs/initramfs.cpio"

echo "---CPIO COMPRESSION DONE"

cp "${OUTDIR}/rootfs/initramfs.cpio.gz" "${OUTDIR}/initramfs.cpio.gz"

echo "----------------------------"
echo "--- MANUAL_LINUX.SH DONE ---"


