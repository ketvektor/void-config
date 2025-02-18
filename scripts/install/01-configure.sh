#!/usr/bin/env bash

set -e

exec &> >(tee "configure.log")

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

ask () {
    read -p "> $1 " -r
    echo
}

menu () {
    PS3="> Choose a number: "
    select i in "$@"
    do
        echo "$i"
        break
    done
}

# Tests
tests () {
    ls /sys/firmware/efi/efivars > /dev/null && \
        ping voidlinux.org -c 1 > /dev/null &&  \
        modprobe zfs &&                         \
        print "Tests ok"
}

select_disk () {
    # Set DISK
    select ENTRY in $(ls /dev/disk/by-id/);
    do
        DISK="/dev/disk/by-id/$ENTRY"
        echo "$DISK" > /tmp/disk
        echo "Installing on $ENTRY."
        break
    done
}

wipe () {
    ask "Do you really want to wipe all data on $ENTRY ?"
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Clear disk
        dd if=/dev/zero of="$DISK" bs=512 count=1
        wipefs -af "$DISK"
        sgdisk -Zo "$DISK"
    fi
}

partition () {
    # EFI part
    # increased EFI size to 1Gb from 512Mb
    print "Creating EFI partition"
    sgdisk -n1:1M:+1G -t1:EF00 -c1:efi "$DISK"
    EFI="$DISK-part1"

    # ZFS part
    # modified to use only a portion of the drive space (2 Tb drive)
    print "Creating ZFS partition"
    sgdisk -n3:0:+512G -t3:bf01 -c3:zfs "$DISK"

    # Separate storage partition utilizing the remainder of drive space
    print "Creating storage partition"
    sgdisk -n4:0:0 -t4:8309 -c4:data # 8309 = LUKS; 8300 = Linux FS
    DATASTOR="$DISK-part4"

    # Inform kernel
    partprobe "$DISK"

    # Format efi part
    sleep 1
    print "Format EFI part"
    mkfs.vfat "$EFI"
}

zfs_passphrase () {
    # Generate key
    print "Set ZFS passphrase"
    read -r -p "> ZFS passphrase: " -s pass
    echo
    echo "$pass" > /etc/zfs/zroot.key
    chmod 000 /etc/zfs/zroot.key
}

luks_create () {
    # Prompt user for password
    read -r -p "> LUKS passphrase " -s lukspass
    echo -n "$LUSKPASS" | cryptsetup luksFormat "$DATASTOR"
    echo -n "$LUSKPASS" | cryptsetup luksOpen "$DATASTOR" luksData
    print "Creating EXT4 FS on $DATASTOR"
    mkfs.ext4 "$DATASTOR" -L "Data"
}

create_pool () {
    # ZFS part
    ZFS="$DISK-part3"

    # Create ZFS pool
    print "Create ZFS pool"
    zpool create -f -o ashift=12                          \
                 -o autotrim=on                           \
                 -O acltype=posixacl                      \
                 -O compression=zstd                      \
                 -O relatime=on                           \
                 -O xattr=sa                              \
                 -O dnodesize=legacy                      \
                 -O encryption=aes-256-gcm                \
                 -O keyformat=passphrase                  \
                 -O keylocation=file:///etc/zfs/zroot.key \
                 -O normalization=formD                   \
                 -O mountpoint=none                       \
                 -O canmount=off                          \
                 -O devices=off                           \
                 -R /mnt                                  \
                 zroot "$ZFS"
}

create_root_dataset () {
    # Slash dataset
    print "Create root dataset"
    zfs create -o mountpoint=none                 zroot/ROOT

    # Set cmdline
    zfs set org.zfsbootmenu:commandline="ro quiet" zroot/ROOT
}

create_system_dataset () {
    print "Create slash dataset"
    zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/"$1"

    # Generate zfs hostid
    print "Generate hostid"
    zgenhostid

    # Set bootfs
    print "Set ZFS bootfs"
    zpool set bootfs="zroot/ROOT/$1" zroot

    # Manually mount slash dataset
    zfs mount zroot/ROOT/"$1"
}

create_home_dataset () {
    print "Create home dataset"
    zfs create -o mountpoint=/ -o canmount=off zroot/data
    zfs create                                 zroot/data/home
    zfs create -o mountpoint=/root             zroot/data/home/root
}

export_pool () {
    print "Export zpool"
    zpool export zroot
}

import_pool () {
    print "Import zpool"
    zpool import -d /dev/disk/by-id -R /mnt zroot -N -f
    zfs load-key zroot
}

mount_system () {
    print "Mount slash dataset"
    zfs mount zroot/ROOT/"$1"
    zfs mount -a

    # Mount EFI part
    print "Mount EFI part"
    EFI="$DISK-part1"
    mkdir -p /mnt/efi
    mount "$EFI" /mnt/efi
}

copy_zpool_cache () {
    # Copy ZFS cache
    print "Generate and copy zfs cache"
    mkdir -p /mnt/etc/zfs
    zpool set cachefile=/etc/zfs/zpool.cache zroot
}

# Main

tests

print "Is this the first install or a second install to dualboot ?"
install_reply=$(menu first dualboot)

select_disk
zfs_passphrase

# If first install
if [[ $install_reply == "first" ]]
then
    # Wipe the disk
    wipe
    # Create partition table
    partition
    # Create ZFS pool
    create_pool
    # Create root dataset
    create_root_dataset
    # Create LUKS-encrypted storage
    luks_create
fi

ask "Name of the slash dataset ?"
name_reply="$REPLY"
echo "$name_reply" > /tmp/root_dataset

if [[ $install_reply == "dualboot" ]]
then
    import_pool
fi

create_system_dataset "$name_reply"

if [[ $install_reply == "first" ]]
then
    create_home_dataset
fi


export_pool
import_pool
mount_system "$name_reply"
copy_zpool_cache

# Finish
echo -e "\e[32mAll OK"
