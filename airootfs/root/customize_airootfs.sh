groupadd docker
! id teto && useradd -m -p "" -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel,docker" -s /usr/bin/fish teto
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service

# Ensure /home/teto exists with correct permissions
mkdir -p /home/teto
chown teto:users /home/teto

# Copy configs and wallpapers
cp -r /root/.config /home/teto/.config
cp -r /root/Imágenes /home/teto/Pictures

# Ensure user owns all config files (including parent directories)
chown -R teto:users /home/teto
chmod 700 /home/teto
chmod -R 755 /home/teto/.config

# Copy wallpapers to root as well
if [ -d /root/wallpapers ]; then
    cp -r /root/wallpapers /home/teto/wallpapers
    chown -R teto:users /home/teto/wallpapers
fi

locale-gen

# Initialize keyring
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

# Enable systemd-timesyncd
systemctl enable systemd-timesyncd.service

# Symlink nerd font config for proper font rendering
mkdir -p /etc/fonts/conf.d
ln -sf /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf /etc/fonts/conf.d/10-nerd-font-symbols.conf

# Run kbuildsycoca6 to rebuild application menu database
if command -v kbuildsycoca6 &> /dev/null; then
    XDG_MENU_PREFIX=arch- kbuildsycoca6 || true
fi

# Fix /boot permissions for random seed security
if [ -d /boot ]; then
    chmod 700 /boot 2>/dev/null || true
fi
