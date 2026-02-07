#!/usr/bin/fish
#Maybe make it a TUI?
#Maybe start at init and then give options like installing, configuring, go to hyprland or exit
#TODO: Add optional windows VM

function arcteto_install
    log Main Hello!

    #Keymap
    log Main "Set the keymap? (Default: la-latin1)"
    set -g keymap la-latin1
    if [ (read -p 'set_color green; echo -n read;set_color normal; echo -n "> [y/n] "'; or exit 1) = y ]
        log Keymap "Setting the keymap"
        wait_key

        set_keymap
    end

    # Disk and installation
    log Main "Picking the disk"
    wait_key

    setup
end
