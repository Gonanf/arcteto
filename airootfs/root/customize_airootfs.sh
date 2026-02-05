groupadd docker
! id teto && useradd -m -p "" -g users -G "adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel,docker" -s /usr/bin/fish teto
xdg-user-dirs-update
cp -r /root/.config /home/teto/.config
chown -R teto /home/teto/.config
