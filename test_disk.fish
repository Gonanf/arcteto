#!/usr/bin/fish
qemu-system-x86_64 -m 16G -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/x64/OVMF_CODE.4m.fd -drive if=pflash,format=raw,file=/usr/share/OVMF/x64/OVMF_VARS.4m.fd -drive file=./.temp.raw,format=raw,media=disk -accel kvm
