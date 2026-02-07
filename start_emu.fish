#!/usr/bin/fish
test -e /tmp/temp.raw; or qemu-img create -f raw /tmp/temp.raw 50G
qemu-system-x86_64 -boot d -cdrom out/arcteto-*.iso -m 16G -drive file=/tmp/temp.raw,format=raw,media=disk -accel kvm
