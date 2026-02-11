#!/usr/bin/fish

rm packages.x86_64
cp /usr/share/archiso/configs/releng/packages.x86_64 .
cat ./airootfs/etc/custom_packages.x86_64 >>packages.x86_64
su -c "
rm -rf out
mkarchiso -w /tmp/archiso-tmp -v .
# rm -rf /tmp/archiso-tmp
sudo chown $(whoami) -R out
exit
"

./start_emu.fish
