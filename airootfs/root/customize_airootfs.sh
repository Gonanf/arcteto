groupadd docker
! id teto && useradd -m -p "" -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel,docker" -s /usr/bin/fish teto
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service

mkdir -p /home/teto
chown -R teto:users /home/teto

cp -r /root/.config /home/teto/.config
cp -r /root/.cache /home/teto/.cache
cp -r /root/Pictures /home/teto/Pictures

# Ensure user owns all config files (including parent directories)
chown -R teto:users /home/teto
chmod 700 /home/teto
chmod -R 755 /home/teto/.config

# if [ -d /root/wallpapers ]; then
#     cp -r /root/wallpapers /home/teto/wallpapers
#     chown -R teto:teto /home/teto/wallpapers
# fi

locale-gen

pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

systemctl enable systemd-timesyncd.service

mkdir -p /etc/fonts/conf.d
ln -sf /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf /etc/fonts/conf.d/10-nerd-font-symbols.conf

if command -v kbuildsycoca6 &> /dev/null; then
    XDG_MENU_PREFIX=arch- kbuildsycoca6 || true
fi

if [ -d /boot ]; then
    chmod 700 /boot 2>/dev/null || true
fi
