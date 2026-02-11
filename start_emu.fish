#!/usr/bin/fish
test -e /tmp/temp.raw; or qemu-img create -f qcow2 /tmp/temp.qcow2 50G
qemu-system-x86_64 -boot d -cdrom out/arcteto-*.iso -m 16G -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/x64/OVMF_CODE.4m.fd -drive if=pflash,format=raw,file=/usr/share/OVMF/x64/OVMF_VARS.4m.fd -drive file=/tmp/temp.qcow2,format=qcow2,media=disk -accel kvm
