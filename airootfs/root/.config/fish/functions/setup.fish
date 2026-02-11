#TODO: Add a greeter and auto login

function prepare_disk
    # Based of Easy Arch

    sudo umount /mnt/home
    sudo umount /mnt/.snapshots
    sudo umount /mnt/root
    sudo umount /mnt/boot
    sudo umount /mnt/

    log Instalation "Warning! This will format the disk and create a new layout, are you sure?"
    #TODO: Missing argument at index 3
    if [ (read -p 'set_color green; echo -n read;set_color normal; echo -n "> [y/n] "'; or exit 1) != y ]
        exit 1
    end

    sudo wipefs -af $disk
    sudo sgdisk -Zo $disk

    log Instalation "Making the partition table..."
    set -l ram_size (grep MemTotal /proc/meminfo | awk '{print $2}')
    if not sudo parted -s $disk mklabel gpt mkpart ESP fat32 1MiB 1025MiB set 1 esp on mkpart ROOT 1025Mib 100%
        log Instalation "Could not make the partition table"
        exit 1
    end

    log Instalation "Probing to the kernel"

    sudo partprobe $disk

    set -g ESP /dev/disk/by-partlabel/ESP

    set -g ROOT /dev/disk/by-partlabel/ROOT

    log Instalation "Formatting the ESP partition"
    sudo mkfs.fat -F 32 $ESP

    log Instalation "Formatting the ROOT partition"
    sudo mkfs.btrfs -f $ROOT

    log Instalation "Creating the subvolumes"
    sudo mount $ROOT /mnt

    sudo btrfs su cr /mnt/@snapshots
    sudo btrfs su cr /mnt/@home
    sudo btrfs su cr /mnt/@root
    sudo btrfs su cr /mnt/@

    sudo umount /mnt

    log Instalation "Succesfully formatted the disk!"
end

function mount_partitions
    log Instalation "Mounting all the partitions and volumes"

    set -l mount_opt "ssd,noatime,compress-force=zstd:3,discard=async"
    sudo mount -o "$mount_opt",subvol=@ $ROOT /mnt

    log Instalation "...Preparing mount Points..."
    sudo mkdir -p /mnt/{etc/sudoers.d,home,root,.snapshots,boot,proc,sys,systemd}

    log Instalation "...Mounting Home..."
    sudo mount -o "$mount_opt",subvol=@home $ROOT /mnt/home

    log Instalation "...Mounting Root..."
    sudo mount -o "$mount_opt",subvol=@root $ROOT /mnt/root
    sudo chmod 750 /mnt/root

    log Instalation "...Mounting Snapshots..."
    sudo mount -o "$mount_opt",subvol=@snapshots $ROOT /mnt/.snapshots

    log Instalation "...Mounting Boot..."
    sudo mount "$ESP" /mnt/boot
end

function install_arcteto
    log Instalation "Figuring out the microcode"
    if grep GenuineIntel /proc/cpuinfo -q
        log Instalation "Intel processor detected"
        set -l microcode intel-ucode
    else
        log Instalation "AMD processor detected"
        set -l microcode amd-ucode
    end

    set -g HOST arcteto

    log Instalation "Enter the Hostname (Default $hostname)"
    read val; or exit 1
    test -n $val; and set -g HOST $val

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
    log Instalation "Enter the user password (Default $user_passwd)"
    read val; or exit 1
    test -n $val; and set -g user_passwd $val

    log Instalation "Installing the packages"
    sudo pacstrap -K /mnt base linux linux-firmware linux-headers $microcode (grep -v '^\s*#'  /etc/custom_packages.x86_64 | grep -v '^\s*$')

    log Instalation "Setting up the hostname"
    echo $HOST | sudo tee /mnt/etc/hostname

    log Instalation "Setting up the locale"
    sudo cp /etc/locale.gen /mnt/etc/
    sudo sed -i "/^#$LANG/s/^#//" /mnt/etc/locale.gen
    echo "LANG=$LANG" | sudo tee /mnt/etc/locale.conf

    log Instalation "Setting up the keymap"
    echo "KEYMAP=$keymap" | sudo tee /mnt/etc/vconsole.conf

    log Instalation "Generating fstab"
    sudo genfstab -U /mnt >>/mnt/etc/fstab

    log Instalation "Setting up the hosts"

    echo "
    127.0.0.1 localhost
    ::1 localhost
    127.0.1.1 $hostname.local $hostname" | sudo tee /mnt/etc/hosts

    log Instalation "Setting up mkinitcpio"
    echo "HOOKS=(systemd autodetect keyboard sd-vconsole modconf block filesystems)" | sudo tee /mnt/etc/mkinitcpio.conf

    log Instalation "Chrooting into the system and setting up timezone, clock, snapshot"
    sudo arch-chroot /mnt /bin/fish -c "
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
    sudo echo "root:$root_passwd" | sudo arch-chroot /mnt chpasswd

    log Instalation "Setting up the user"
    sudo arch-chroot /mnt groupadd docker
    echo "%wheel ALL=(ALL:ALL) ALL" | sudo tee /mnt/etc/sudoers.d/wheel
    sudo arch-chroot /mnt useradd -m -G wheel,docker -s /bin/bash "$username"
    sudo echo "$username:$user_passwd" | sudo arch-chroot /mnt chpasswd
    sudo arch-chroot /mnt xdg-user-dirs-update

    log Instalation "Setting up the backups"
    sudo mkdir -p /mnt/etc/pacman.d/hooks
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
    " | sudo tee /mnt/etc/pacman.d/hooks/50-bootbackup.hook

    log Instalation "Setting up zram"

    echo "
    [zram0]
    zram-size = ram / 2" | sudo tee /mnt/etc/systemd/zram-generator.conf

    log Instalation "Copying the config"
    sudo cp -r ./.config "/mnt/home/$username/"

    sudo cp /root/.profile "/mnt/home/$username/.profile"

    log Instalation "Setting up pacman"
    sudo cp /etc/pacman.conf /mnt/etc/
    sudo sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/;s/^#\[multilib\]/[multilib]/;s/^[[:space:]]*#([[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman.d\/mirrorlist)/\1/' /mnt/etc/pacman.conf

    log Instalation "Enabling snapshots, integrity verification and Out Of Memory protections"
    set services reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer systemd-oomd
    for service in $services
        sudo systemctl enable "$service" --root=/mnt
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

function setup
    list_disks

    prepare_disk

    mount_partitions

    install_arcteto
end
