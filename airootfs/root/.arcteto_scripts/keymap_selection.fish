source ~/.arcteto_scripts/log.fish
source ~/.arcteto_scripts/wait_key.fish

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
    log Keymap "Put 'Y' to diplay options, or write the name of the keymap directly"
    read -g keymap; or exit 1
    if [ $keymap = Y ]
        recurse_path /usr/share/kbd/keymaps
    end
    if not localectl set-keymap $keymap
        log Keymap "There was an error, try again"
        wait_key
        set_keymap
    else
        log Keymap "Keymap set successfully to $keymap"
        wait_key
    end

end

set_keymap
