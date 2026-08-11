function focuslock-engage
    # FocusLock engage — run this on TTY1 (agent session) to start a focus block.
    # Generates a Hermes-only passkey, writes its SHA256 to the focuslock PAM secret
    # on the MAIN user (chaos), locks TTY1 via hyprlock (PAM service 'focuslock'),
    # and shoves the user to the target TTY (study=2, work=4, ...). The locked env
    # never knows the secret — unlock always happens back on TTY1.
    set -l TARGET_TTY 2
    set -l AGENT_USER (whoami)

    # allow override: focuslock-engage --tty 4  (for work)
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --tty
                set TARGET_TTY $argv[(math $i + 1)]; set i (math $i + 1)
        end
        set i (math $i + 1)
    end

    set -x DISPLAY (test -n "$DISPLAY"; and echo $DISPLAY; or echo :0)
    set -x WAYLAND_DISPLAY (test -n "$WAYLAND_DISPLAY"; and echo $WAYLAND_DISPLAY; or echo wayland-1)
    set -x XDG_RUNTIME_DIR (test -n "$XDG_RUNTIME_DIR"; and echo $XDG_RUNTIME_DIR; or echo /run/user/(id -u))

    if test -z "$HYPRLAND_INSTANCE_SIGNATURE"
        set -x HYPRLAND_INSTANCE_SIGNATURE (ls -d /run/user/(id -u)/hypr/*/.socket.sock 2>/dev/null | head -1 | sed 's#.*/hypr/##; s#/.socket.sock##')
    end

    set -l PASSKEY (openssl rand -hex 12)
    set -l SECRET_DIR "$HOME/.local/state/focuslock"
    set -l SECRET_FILE "$SECRET_DIR/secret.sha256"
    mkdir -p "$SECRET_DIR"
    chmod 700 "$SECRET_DIR"
    printf '%s' "$PASSKEY" | sha256sum | awk '{print $1}' > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE"

    # Hand the passkey to the agent (it stores it; never printed to the user's terminal).
    echo "$PASSKEY" > "$HOME/.hermes/focuslock_custody"
    chmod 600 "$HOME/.hermes/focuslock_custody"

    # Lock the session with hyprlock (uses PAM service 'focuslock' = Hermes-only passkey).
    hyprlock >/dev/null 2>&1 &
    sleep 2

    # Shove the user to the target TTY (study=2, work=4, ...). Requires sudoers chvt rule.
    sudo chvt $TARGET_TTY 2>/dev/null; or true

    notify-send "FocusLock ON" "Modo focus. TTY1 lockeado. Passkey custodiada por Hermes."
end
