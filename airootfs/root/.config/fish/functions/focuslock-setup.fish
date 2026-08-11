function focuslock-setup
    # FocusLock environment setup for Arcteto — visual (zenity) automated installer.
    # Creates an isolated study user (TTY2) with filtered DNS, a hyprlock PAM module
    # that only the agent's passkey can unlock, and TTY redirection.
    #
    # This is the Arcteto-packaged version of the manually-built FocusLock described
    # in the project blog (Blogs/arcteto-focuslock-kateto.md).

    set -l STUDY_USER study
    set -l STUDY_UID 1001
    set -l AGENT_USER chaos
    set -l DNS_PORT 5335

    # --- Visual helper: use zenity if available, else fall back to CLI ---
    function _fl_msg
        if command -v zenity >/dev/null 2>&1
            zenity --info --title "FocusLock" --text "$argv[1]" --width 400 2>/dev/null
        else
            echo "FocusLock: $argv[1]"
        end
    end
    function _fl_confirm
        if command -v zenity >/dev/null 2>&1
            zenity --question --title "FocusLock" --text "$argv[1]" --width 400 2>/dev/null
            return $status
        else
            read -P "FocusLock: $argv[1] [y/N] " -l ans
            test "$ans" = y; and return 0; or return 1
        end
    end
    function _fl_entry
        if command -v zenity >/dev/null 2>&1
            zenity --entry --title "FocusLock" --text "$argv[1]" --entry-text "$argv[2]" --width 400 2>/dev/null
        else
            echo -n "FocusLock: $argv[1] ($argv[2]): "; read -l val; test -n "$val"; and echo $val; or echo $argv[2]
        end
    end
    function _fl_progress_start
        if command -v zenity >/dev/null 2>&1
            echo "0" | zenity --progress --title "FocusLock" --text "Iniciando..." --percentage=0 --auto-close --width 400 2>/dev/null &
            set -g _FL_PROGRESS_PID $last_pid
        end
    end
    function _fl_progress
        if set -q _FL_PROGRESS_PID
            echo "$argv[1]" | zenity --progress --title "FocusLock" --text "$argv[2]" --percentage=$argv[1] --auto-close --width 400 2>/dev/null &
            # replace previous
            kill $_FL_PROGRESS_PID 2>/dev/null; set -g _FL_PROGRESS_PID $last_pid
        else
            echo "FocusLock [$argv[1]%]: $argv[2]"
        end
    end

    # Must run as root (or with sudo). The script itself escalates via sudo.
    if not test (id -u) -eq 0
        _fl_msg "Este script necesita sudo. Se te pedirá la contraseña."
    end

    # --- Confirm ---
    _fl_confirm "¿Configurar FocusLock en este sistema Arcteto?\n\nSe creará un usuario de estudio aislado (TTY2) con DNS filtrado y un lock de pantalla que solo el agente puede desbloquear."; or return 0

    # --- Ask for study username ---
    set STUDY_USER (_fl_entry "Nombre del usuario de estudio (aislado en TTY2):" $STUDY_USER)
    set STUDY_UID (id -u $STUDY_USER 2>/dev/null; or echo $STUDY_UID)

    _fl_progress_start
    _fl_progress 10 "Creando usuario de estudio '$STUDY_USER'..."

    # --- 1. Create study user ---
    if not id -u $STUDY_USER >/dev/null 2>&1
        sudo useradd -m -s /bin/fish $STUDY_USER
    end
    sudo mkdir -p /home/$STUDY_USER/.local/state/focuslock
    sudo chown -R $STUDY_USER:$STUDY_USER /home/$STUDY_USER/.local/state/focuslock
    # study needs input/seat groups for mouse/keyboard on its own TTY
    sudo usermod -aG input,video,seat,tty $STUDY_USER
    sudo systemctl enable --now seatd 2>/dev/null

    _fl_progress 25 "Configurando PAM focuslock (passkey del agente)..."

    # --- 2. PAM focuslock module ---
    echo "#%PAM-1.0
auth requisite pam_exec.so quiet expose_authtok /usr/local/bin/focuslock-check
auth required pam_permit.so" | sudo tee /etc/pam.d/focuslock >/dev/null

    echo '#!/bin/bash
home=$(getent passwd "$PAM_USER" | cut -d: -f6)
secret="$home/.local/state/focuslock/secret.sha256"
[ -r "$secret" ] || exit 1
read -r pw
hash=$(printf "%s" "$pw" | sha256sum | awk "{print \$1}")
[ "$hash" = "$(cat "$secret")" ] && exit 0 || exit 1' | sudo tee /usr/local/bin/focuslock-check >/dev/null
    sudo chmod 755 /usr/local/bin/focuslock-check

    _fl_progress 40 "Configurando hyprlock..."

    # --- 3. hyprlock config (uses PAM focuslock) ---
    sudo mkdir -p /home/$AGENT_USER/.config/hypr
    echo 'auth {
    pam:enabled = true
    pam:module = focuslock
}

background {
    color = rgba(20, 20, 25, 1.0)
}

input-field {
    size = 30%, 5%
    outline_thickness = 3
    inner_color = rgba(0, 0, 0, 0.3)
    outer_color = rgba(50, 50, 60, 1.0)
    font_color = rgb(200, 200, 200)
    position = 0, -10
    halign = center
    valign = center
}' | sudo tee /home/$AGENT_USER/.config/hypr/hyprlock.conf >/dev/null
    sudo chown $AGENT_USER:$AGENT_USER /home/$AGENT_USER/.config/hypr/hyprlock.conf

    _fl_progress 55 "Configurando DNS filtrado (dnsmasq)..."

    # --- 4. dnsmasq filtered resolver ---
    echo "port=$DNS_PORT
listen-address=127.0.0.1
bind-interfaces
no-resolv
server=1.1.1.1
address=/youtube.com/0.0.0.0
address=/reddit.com/0.0.0.0
address=/x.com/0.0.0.0
address=/twitter.com/0.0.0.0
address=/tiktok.com/0.0.0.0
address=/www.tiktok.com/0.0.0.0
address=/vm.tiktok.com/0.0.0.0
address=/tiktokcdn.com/0.0.0.0
address=/byteoversea.com/0.0.0.0
address=/dns.google/0.0.0.0
address=/cloudflare-dns.com/0.0.0.0
address=/dns.quad9.net/0.0.0.0" | sudo tee /etc/dnsmasq-focuslock.conf >/dev/null

    # systemd service for dnsmasq-focuslock
    echo "[Unit]
Description=FocusLock DNSmasq instance
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/usr/bin/bash -c 'pkill -f \"dnsmasq.*$DNS_PORT\" 2>/dev/null || true'
ExecStart=/usr/bin/dnsmasq -k -C /etc/dnsmasq-focuslock.conf
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/dnsmasq-focuslock.service >/dev/null

    _fl_progress 70 "Configurando nftables (redirección de DNS)..."

    # --- 5. nftables focuslock table ---
    echo "table inet focuslock;
delete table inet focuslock;

table inet focuslock {
    chain output_nat {
        type nat; hook output; priority dstnat; policy accept;
        meta skuid $STUDY_UID udp dport 53 dnat ip to 127.0.0.1:$DNS_PORT
        meta skuid $STUDY_UID tcp dport 53 dnat ip to 127.0.0.1:$DNS_PORT
    }

    chain output_filter {
        type filter; hook output; priority filter; policy accept;
        meta skuid $STUDY_UID oif \"lo\" accept
        meta skuid $STUDY_UID tcp dport 853 drop
        meta skuid $STUDY_UID udp dport 853 drop
        meta skuid $STUDY_UID udp dport 443 drop
    }
}" | sudo tee /etc/nftables-focuslock.conf >/dev/null

    sudo nft -f /etc/nftables-focuslock.conf
    # make nft rules persist: load via a drop-in or include in main nftables.conf
    if not grep -q "include \"nftables-focuslock.conf\"" /etc/nftables.conf 2>/dev/null
        echo "include \"nftables-focuslock.conf\"" | sudo tee -a /etc/nftables.conf >/dev/null
    end
    sudo systemctl enable --now dnsmasq-focuslock.service

    _fl_progress 85 "Configurando autologin TTY2 y sudoers..."

    # --- 6. TTY2 autologin for study ---
    sudo mkdir -p /etc/systemd/system/getty@tty2.service.d
    echo "[Service]
ExecStart=
ExecStart=-/usr/bin/agetty -a $STUDY_USER --noclear %I \$TERM" | sudo tee /etc/systemd/system/getty@tty2.service.d/override.conf >/dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart getty@tty2

    # --- 7. sudoers for chvt (agent can switch TTY without password) ---
    echo "$AGENT_USER ALL=(root) NOPASSWD: /usr/bin/chvt" | sudo tee /etc/sudoers.d/focuslock >/dev/null
    sudo chmod 440 /etc/sudoers.d/focuslock

    _fl_progress 100 "FocusLock configurado."
    _fl_msg "FocusLock listo.\n\n- Usuario de estudio: $STUDY_USER (TTY2, autologin)\n- DNS filtrado en :$DNS_PORT\n- hyprlock usa PAM 'focuslock' (passkey del agente)\n\nPara activar: focuslock-engage"
end
