function focuslock-engage
    # FocusLock engage — run this on TTY1 (agent session) to start a study block.
    # Generates a Hermes-only passkey, writes its SHA256 to the focuslock PAM secret,
    # locks the session via hyprlock (which uses PAM service 'focuslock'), and shoves
    # the user to TTY2 (study environment). Noctalia is NOT involved in the lock.
    set -l STUDY_TTY 2
    set -l AGENT_USER (whoami)

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

    # Shove the user to TTY2 (study environment). Requires the sudoers chvt rule.
    sudo chvt $STUDY_TTY 2>/dev/null; or true

    notify-send "FocusLock ON" "Modo estudio. TTY1 lockeado. Passkey custodiada por Hermes."
end
