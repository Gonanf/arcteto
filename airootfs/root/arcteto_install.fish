#!/usr/bin/fish
#Maybe make it a TUI?
#Maybe start at init and then give options like installing, configuring, go to hyprland or exit
function log
    set_color blue
    echo -n "> "
    set_color green
    echo -n "["$argv[1]"] "
    set_color bryellow
    echo $argv[2]
end

function wait_key
    log Wait "Press any key to continue"
    read -n 1 -s -p ""; or exit 1
    echo ""
end

function recurse_path
    set -l folders (ls $argv[1])

    for f in (seq (count $folders))
        log $f (basename $folders[$f])
    end

    log Keymap "Enter between [1..$(count $folders)]"
    read -n 3 idx; or exit 1
    if begin
            not string match -q -r '^\+?[0-9]+$' -- $idx; or test $idx -ge (count $folders) -o $idx -lt 0
        end
        log Recurse "Wrong option, try again"
        wait_key
        recurse_path $argv[1]
    end
    if test -f "$argv[1]/$folders[$idx]"
        set -g keymap (basename "$argv[1]/$folders[$idx]" .map.gz)
    else
        recurse_path "$argv[1]/$folders[$idx]"
    end

end

function set_keymap
    recurse_path /usr/share/kbd/keymaps
    if not localectl set-keymap $keymap
        log Keymap "There was an error, try again"
        wait_key
        set_keymap
    else
        log Keymap "Keymap set successfully to $keymap"
        wait_key
    end

end

function list_disks
    set -l disks (lsblk -dn -o NAME,TYPE,SIZE | awk '$2=="disk"{print "/dev/"$1 "  " $3}')
    for d in (seq (count $disks))
        log $d $disks[$d]
    end

    read -n 3 idx; or exit 1
    if begin
            not string match -q -r '^\+?[0-9]+$' -- $idx; or test $idx -gt (count $disks) -o $idx -lt 0
        end
        log Recurse "Wrong option, try again"
        wait_key
        list_disks
    end

    set -g disk (string split " " "$disks[$idx]")[1]
end

log Main Hello!

#Keymap
log Main "Set the keymap?"
if [ (read -p 'set_color green; echo -n read;set_color normal; echo -n "> [y/n] "'; or exit 1) = y ]
    log Keymap "Setting the keymap"
    wait_key

    set_keymap
end

log Main "Picking the disk"
wait_key

list_disks

if [$USER != "root"]
    log Main "Entering root mode"
    su
end

log Main "Warning! This will format the disk and create a new layout, are you sure?"
if [ (read -p 'set_color green; echo -n read;set_color normal; echo -n "> [y/n] "'; or exit 1) != y ]
    exit 1
end
wipefs -af "/dev/$disk"
sgdisk -Zo "/dev/$disk"

set -l ram_size (grep MemTotal /proc/meminfo | awk '{print $2}')
(echo g; echo n; echo ""; echo ""; echo +1G; echo n; echo ""; echo ""; echo "+$ram_size"K ; echo n; echo ""; echo ""; echo ""; echo w) | fdisk "/dev/$disk"
mkfs.btrfs "/dev/$disk"
