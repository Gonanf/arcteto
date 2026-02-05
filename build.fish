#!/usr/bin/fish

rm packages.x86_64
cp /usr/share/archiso/configs/releng/packages.x86_64 .
cat custom_packages.x86_64 >>packages.x86_64
sudo mkarchiso -w /tmp/archiso-tmp -r -v .
sudo rm -rf /tmp/archiso-tmp
test -e /tmp/temp.raw; or qemu-img create -f raw /tmp/temp.raw 25G
qemu-system-x86_64 -boot d -cdrom out/arcteto-*.iso -m 16G -drive file=/tmp/temp.raw,format=raw -accel kvm
