function prepare_disk
    # Based of Easy Arch

    sudo umount /mnt/home
    sudo umount /mnt/.snapshots
    sudo umount /mnt/root
    sudo umount /mnt/boot
    sudo umount /mnt/

    log Instalation "Warning! This will format the disk and create a new layout, are you sure?"
    if not set -ql argv[1]; and [ (read -p 'set_color green; echo -n read;set_color normal; echo -n "> [y/n] "'; or exit 1) != y ]
        exit 1
    end

    sudo wipefs -af $disk

    log Instalation "Making the partition table..."
    set -l ram_size (grep MemTotal /proc/meminfo | awk '{print $2}')
    if not sudo parted -s $disk mklabel gpt mkpart ESP fat32 1MiB 1025MiB set 1 esp on mkpart ROOT 1025MiB 100%
        log Instalation "Could not make the partition table"
        exit 1
    end

    log Instalation "Probing to the kernel"
    sleep 2
    sudo sgdisk --change-name=1:ESP --change-name=2:ROOT $disk
    sudo partprobe $disk
    sleep 1
    sync

    set -g ESP /dev/disk/by-partlabel/ESP

    set -g ROOT /dev/disk/by-partlabel/ROOT

    log Instalation "Formatting the ESP partition"
    sudo mkfs.fat -F 32 $ESP

    log Instalation "Formatting the ROOT partition"
    sudo mkfs.btrfs -f $ROOT
    sync

    log Instalation "Creating the subvolumes"
    sudo mount $ROOT /mnt

    sudo btrfs su cr /mnt/@snapshots
    sudo btrfs su cr /mnt/@home
    sudo btrfs su cr /mnt/@root
    sudo btrfs su cr /mnt/@

    sudo umount /mnt

    log Instalation "Verifying subvolumes exist"
    sudo mount $ROOT /mnt
    sudo btrfs subvolume list /mnt
    sudo umount /mnt
    sync

    log Instalation "Succesfully formatted the disk!"
end

function mount_partitions
    log Instalation "Mounting all the partitions and volumes"

    set -l mount_opt "ssd,noatime,compress-force=zstd:3,discard=async"

    log Instalation "Mounting / subvolume: $ROOT with options: $mount_opt,subvol=@"
    if not sudo mount -o "$mount_opt",subvol=@ $ROOT /mnt
        log Instalation "Failed to mount root subvolume"
        exit 1
    end

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
    not set -ql argv[1]; and read val; or exit 1
    test -n $val; and set -g HOST $val

    set -g LANG es_AR.UTF-8

    log Instalation "Enter the Language (Default $LANG)"
    not set -ql argv[1]; and read val; or exit 1
    test -n $val; and set -g LANG $val

    set -g root_passwd iusearchbtw
    log Instalation "Enter the root password (Default $root_passwd)"
    not set -ql argv[1]; and read val; or exit 1
    test -n $val; and set -g root_passwd $val

    set -g username teto
    log Instalation "Enter the user name (Default $username)"
    not set -ql argv[1]; and read val; or exit 1
    test -n $val; and set -g username $val

    set -g user_passwd kasaneteto
    log Instalation "Enter the user password (Default $user_passwd)"
    not set -ql argv[1]; and read val; or exit 1
    test -n $val; and set -g user_passwd $val

    log Instalation "Installing the packages"
    sudo pacstrap -K /mnt base linux linux-firmware linux-headers $microcode (grep -v '^\s*#'  /etc/custom_packages.x86_64 | grep -v '^\s*$')

    log Instalation "Setting up the hostname"
    echo $HOST | sudo tee /mnt/etc/hostname

    log Instalation "Setting up the locale"
    sudo cp /etc/locale.gen /mnt/etc/
    sudo sed -i "/^#$LANG/s/^#//" /mnt/etc/locale.gen
    echo "LANG=$LANG" | sudo tee /mnt/etc/locale.conf

    set -q keymap; or set -g keymap la-latin1
    log Instalation "Setting up the keymap"
    echo "
    KEYMAP=$keymap
    FONT=ter-v16n
    XKBLAYOUT=latam
    XKBMODEL=pc105" | sudo tee /mnt/etc/vconsole.conf

    log Instalation "Generating fstab"
    sudo genfstab -U /mnt | sudo tee /mnt/etc/fstab

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

    umount /home/.snapshots
    rm -r /home/.snapshots
    snapper --no-dbus -c home create-config /home
    btrfs subvolume delete /home/.snapshots
    mkdir /home/.snapshots
    mount -a
    chmod 750 /home/.snapshots
    "

    log Instalation "Setting up autologin into hyprland"
    sudo mkdir -p /mnt/etc/systemd/system/getty@tty1.service.d/
    sudo touch /mnt/etc/systemd/system/getty@tty1.service.d/override.conf
    echo "
    [Service]
    ExecStart=
    ExecStart=-/usr/bin/agetty --autologin $username --noclear %I \$TERM" | sudo tee /mnt/etc/systemd/system/getty@tty1.service.d/override.conf

    log Instalation "Installing Systemd boot"
    sudo arch-chroot -S /mnt /bin/fish -c "bootctl install"

    log Instalation "Setting up loaders"
    sudo echo "
    title   ArcTeto
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
    options root=PARTLABEL=ROOT rw rootflags=subvol=@ add_efi_memmap" | sudo tee /mnt/boot/loader/entries/arcteto.conf

    sudo echo "
  default  arcteto.conf
timeout  4
console-mode max" | sudo tee /mnt/boot/loader/loader.conf

    log Instalation "Setting up root password"
    echo "root:$root_passwd" | sudo arch-chroot /mnt chpasswd

    log Instalation "Setting up the user"
    sudo arch-chroot /mnt groupadd docker
    echo "%wheel ALL=(ALL:ALL) ALL" | sudo tee /mnt/etc/sudoers.d/wheel
    sudo arch-chroot /mnt useradd -m -G wheel,docker -s /bin/fish "$username"
    sudo echo "$username:$user_passwd" | sudo arch-chroot /mnt chpasswd

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
    sudo cp ./.profile "/mnt/home/$username/.profile"

    log Instalation "Owning config files"
    sudo arch-chroot /mnt chown $username:users /home/$username
    sudo arch-chroot /mnt chmod 700 /home/$username
    sudo arch-chroot /mnt chown -R $username:users /home/$username/.config
    sudo arch-chroot /mnt chown $username:users /home/$username/.profile
    sudo arch-chroot /mnt chmod -R 755 /home/$username/.config

    log Instalation "Setting up pacman"
    sudo sed -Ei 's/^#(Color)$/\1\nILoveCandy/;s/^#(ParallelDownloads).*/\1 = 10/' /mnt/etc/pacman.conf
    echo "
    [multilib]
    Include = /etc/pacman.d/mirrorlist" | sudo tee -a /mnt/etc/pacman.conf

    log Instalation "Enabling snapshots, integrity verification and Out Of Memory protections"
    set services reflector.timer snapper-timeline.timer snapper-cleanup.timer btrfs-scrub@-.timer btrfs-scrub@home.timer btrfs-scrub@var-log.timer btrfs-scrub@\\x2esnapshots.timer systemd-oomd systemd-networkd systemd-resolved sshd
    for service in $services
        sudo systemctl enable "$service" --root=/mnt
    end
    sudo systemctl --user enable xdg-user-dirs --root=/mnt

    log Instalation "Applying system fixes"
    sudo arch-chroot /mnt /bin/fish -c "
    mkdir -p /etc/fonts/conf.d
    ln -sf /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf /etc/fonts/conf.d/10-nerd-font-symbols.conf

    if [ -d /boot ]; then
        chmod 700 /boot 2>/dev/null || true
    fi

    if command -v kbuildsycoca6 &> /dev/null; then
        XDG_MENU_PREFIX=arch- kbuildsycoca6 || true
    fi

    systemctl enable systemd-timesyncd.service
    "

    log Instalation "Copying wallpapers"
    if [ -d /root/wallpapers ]; then
        sudo mkdir -p /mnt/home/$username/wallpapers
        sudo cp -r /root/wallpapers/* /mnt/home/$username/wallpapers/
        sudo arch-chroot /mnt chown -R $username:users /home/$username/wallpapers
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
    argparse d/disk y/yes -- $argv; or return

    if not set -ql _flag_disk
        list_disks
    else
        set -g disk $_flag_disk
    end

    prepare_disk $_flag_yes

    mount_partitions $_flag_yes

    install_arcteto $_flag_yes
end
