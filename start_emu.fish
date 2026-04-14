#!/usr/bin/fish
set -q ARCTETO_ISO_PATH; or set ARCTETO_ISO_PATH ./temp.raw
set -q ARCTETO_EXTRA_PARAMS; or set ARCTETO_EXTRA_PARAMS -accel kvm
set -q ARCTETO_MEMORY; or set ARCTETO_MEMORY 16G
set -q ARCTETO_SIZE; or set ARCTETO_SIZE 50G

touch $ARCTETO_ISO_PATH
if not test -G $ARCTETO_ISO_PATH
	echo "You do not have access to the ISO path, changing ownership..."
	sudo chown (whoami):(whoami) $ARCTETO_ISO_PATH
end

if not test -G /usr/share/OVMF/x64/OVMF_VARS.4m.fd
	echo "You do not have access to the UEFI vars, changing ownership..."
	sudo chown (whoami):(whoami) /usr/share/OVMF/x64/OVMF_VARS.4m.fd
end

test -e $ARCTETO_ISO_PATH; or qemu-img create -f raw $ARCTETO_ISO_PATH $ARCTETO_SIZE
qemu-system-x86_64 -boot d -cdrom out/arcteto-*.iso -m $ARCTETO_MEMORY -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/x64/OVMF_CODE.4m.fd -drive if=pflash,format=raw,file=/usr/share/OVMF/x64/OVMF_VARS.4m.fd -drive file=$ARCTETO_ISO_PATH,format=raw,media=disk -virtfs local,path=./airootfs/root/.config/fish,mount_tag=host0,security_model=passthrough $ARCTETO_EXTRA_PARAMS
