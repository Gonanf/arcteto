#!/usr/bin/fish
#Maybe make it a TUI?
#Maybe start at init and then give options like installing, configuring, go to hyprland or exit
#TODO: Add optional windows VM
source ./.arcteto_scripts/log.fish
source ./.arcteto_scripts/wait_key.fish

log Main Hello!

#Keymap
log Main "Set the keymap?"
if [ (read -p 'set_color green; echo -n read;set_color normal; echo -n "> [y/n] "'; or exit 1) = y ]
    log Keymap "Setting the keymap"
    wait_key

    source ~/.arcteto_scripts/keymap_selection.fish
end

# Disk and installation
log Main "Picking the disk"
wait_key

source ~/.arcteto_scripts/setup.fish
