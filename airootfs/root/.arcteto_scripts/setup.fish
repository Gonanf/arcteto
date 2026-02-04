source ./log.fish
source ./wait_key.fish

function prepare_disk
    # Based of Easy Arch
    log Instalation "Warning! This will format the disk and create a new layout, are you sure?"
    if [ (read -p 'set_color green; echo -n read;set_color normal; echo -n "> [y/n] "'; or exit 1) != y ]
        exit 1
    end
    wipefs -af "/dev/$disk"
    sgdisk -Zo "/dev/$disk"

    log Instalation "Making the partition table..."
    set -l ram_size (grep MemTotal /proc/meminfo | awk '{print $2}')
    if not parted -s "/dev/$disk" mklabel gpt mkpart ESP fat32 1MiB 1025MiB set 1 esp on mkpart ROOT 1025Mib 100%
        log Instalation "Could not make the partition table"
        exit 1
    end

    log Instalation "Probing to the kernel"
    partprobe "/dev/$disk"

    set -g ESP /dev/disk/by-partlabel/ESP

    set -g ROOT /dev/disk/by-partlabel/ROOT

    log Instalation "Formatting the ESP partition"
    mkfs.fat -F 32 $ESP

    log Instalation "Formatting the ROOT partition"
    mkfs.btrfs $ROOT

    log Instalation "Creating the subvolumes"
    mount $ROOT /mnt

    btrfs su cr /mnt/@snapshots
    btrfs su cr /mnt/@home
    btrfs su cr /mnt/@root
    btrfs su cr /mnt/@

    umount /mnt

    log Instalation "Succesfully formatted the disk!"
end

function mount_partitions
    log Instalation "Mounting all the partitions and volumes"

    set -l mount_opt "ssd,noatime,compress-force=zstd:3,discard=async"
    mount -o "$mount_opt",subvol=@ $ROOT /mnt

    log Instalation "...Preparing mount Points..."
    mkdir -p /mnt/{home,root,.snapshots,boot}

    log Instalation "...Mounting Home..."
    mount -o "$mount_opt",subvol=@home /mnt/home

    log Instalation "...Mounting Root..."
    mount -o "$mount_opt",subvol=@root /mnt/root
    chmod 750 /mnt/root

    log Instalation "...Mounting Snapshots..."
    mount -o "$mount_opt",subvol=@snapshots /mnt/.snapshots

    log Instalation "...Mounting Boot..."
    mount "$ESP" /mnt/boot
end

function install_arcteto
    log Instalation "Figuring out the microcode"
    if [ (grep vendor_id /proc/cpuinfo) = *"GenuineIntel" ]
        log Instalation "Intel processor detected"
        set -l microcode intel-ucode
    else
        log Instalation "AMD processor detected"
        set -l microcode amd-ucode
    end

    set -g hostname arcteto

    log Instalation "Enter the Hostname (Default $hostname)"
    read val; or exit 1
    test -n $val; and set -g hostname $val

    set -g LANG es_AR.UTF-8

    log Instalation "Enter the Language (Default $LANG)"
    read val; or exit 1
    test -n $val; and set -g LANG $val

    set -g root_passwd iusearchbtw
    log Instalation "Enter the root password (Default $root_passwd)"
    read val; or exit 1
    test -n $val; and set -g root_passwd $val

    set -g username Kasane
    log Instalation "Enter the user name (Default $username)"
    read val; or exit 1
    test -n $val; and set -g username $val

    set -g user_passwd kasaneteto
    log Instalation "Enter the user password (Default $root_passwd)"
    read val; or exit 1
    test -n $val; and set -g user_passwd $val

    log Instalation "Installing the packages"
    packstrap -K /mnt base linux linux-firmware linux-headers $microcode (awk '{print $1}' ~/custom_packages.x86_64)

    log Instalation "Setting up the hostname"
    echo $hostname >/mnt/etc/hostname

    log Instalation "Setting up the locale"
    sed -i "/^#$LANG/s/^#//" /mnt/etc/locale.gen
    echo "LANG=$LANG" >/mnt/etc/locale.conf

    log Instalation "Setting up the keymap"
    echo "KEYMAP=$keymap" >/mnt/etc/vconsole.conf

    log Instalation "Generating fstab"
    genfstab -U /mnt >>/mnt/etc/fstab

    log Instalation "Setting up the hosts"

    echo "
    127.0.0.1 localhost
    ::1 localhost
    127.0.1.1 $hostname.local $hostname" >/mnt/etc/hosts

    log Instalation "Setting up mkinitcpio"
    echo "HOOKS=(systemd autodetect keyboard sd-vconsole modconf block filesystems)" >/mnt/etc/mkinitcpio.conf

    log Instalation "Chrooting into the system and setting up timezone, clock, snapshot"
    arch-chroot /mnt /bin/fish -c "
    ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime

    hwclock --systohc

    locale-gen

    mkinitcpio -P

    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots
    mkdir /.snapshots
    mount -a
    chmod 750 /.snapshots

    bootctl install
    "

    log Instalation "Setting up root password"
    echo "root:$root_passwd" | arch-chroot /mnt chpasswd

    log Instalation "Setting up the user"
    arch-chroot /mnt groupadd docker
    echo "%wheel ALL=(ALL:ALL) ALL" >/mnt/etc/sudoers.d/wheel
    arch-chroot /mnt useradd -m -G wheel,docker -s /bin/bash "$username"
    echo "$username:$user_passwd" | arch-chroot /mnt chpasswd
    arch-chroot /mnt xdg-user-dirs-update

    log Instalation "Setting up the backups"
    mkdir /mnt/etc/pacman.d/hooks
    echo "
    [Trigger]
    Operation = Upgrade
    Operation = Install
    Operation = Remove
    Type = Path
    Target = usr/lib/modules/*/vmlinuz

    [Action]
    Depends = rsync
    Description = Backing up /boot...
    When = PostTransaction
    Exec = /usr/bin/rsync -a --delete /boot /.bootbackup
    " >/mnt/etc/pacman.d/hooks/50-bootbackup.hook

    log Instalation "Setting up zram"
    echo "
    [zram0]
    zram-size = ram / 2" >/mnt/etc/systemd/zram-generator.conf

    log Instalation "Copying the config"
    cp -r /root/.config "/mnt/home/$username/"

    log Instalation "Setting up pacman"
    sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /mnt/etc/pacman.conf

    log Instalation "Enabling snapshots, integrity verification and Out Of Memory protections"
    set services reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer grub-btrfsd.service systemd-oomd
    for service in $services
        do
        systemctl enable "$service" --root=/mnt
        done

    end

    log Instalation "Installed correctly"
end

function list_disks
    set -l disks (lsblk -dn -o NAME,TYPE,SIZE | awk '$2=="disk"{print "/dev/"$1 "  " $3}')
    for d in (seq (count $disks))
        log $d $disks[$d]
    end

    read -n 3 idx; or exit 1
    if begin
            not string match -q -r '^\+?[0-9]+$' -- $idx; or test $idx -gt (count $disks) -o $idx -lt 0
        end
        log Recurse "Wrong option, try again"
        wait_key
        list_disks
    end

    set -g disk (string split " " "$disks[$idx]")[1]
end

list_disks

if [$USER != "root"]
    log Instalation "Entering root mode"
    su
end

prepare_disk

mount_partitions

install_arcteto
