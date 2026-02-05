groupadd docker
! id teto && useradd -m -p "" -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel,docker" -s /usr/bin/fish teto
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service
cp -r /root/.config /home/teto/.config
cp -r /root/Imágenes /home/teto/Pictures
chown -R teto /home/teto/.config
chown -R teto /home/teto/Pictures
locale-gen
