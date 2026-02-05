#!/usr/bin/fish

rm packages.x86_64
cp /usr/share/archiso/configs/releng/packages.x86_64 .
cat custom_packages.x86_64 >>packages.x86_64
su -c "
rm -rf out
mkarchiso -w /tmp/archiso-tmp -r -v .
rm -rf /tmp/archiso-tmp
sudo chown $(whoami) -R out
exit
"
test -e /tmp/temp.raw; or qemu-img create -f raw /tmp/temp.raw 25G
qemu-system-x86_64 -boot d -cdrom out/arcteto-*.iso -m 16G -drive file=/tmp/temp.raw,format=raw,media=disk -accel kvm
