function arcteto-env
    # Arcteto isolated environment creator — visual (zenity) automated setup.
    #
    # Creates ANY isolated environment on Arcteto: a separate TTY, optionally a
    # separate user, optionally filtered DNS (blocks arbitrary domains), and a
    # set of autostart apps. This is the generic engine behind FocusLock's study
    # environment, the streaming environment, or any other sandbox you want.
    #
    # Usage (interactive, visual):
    #   arcteto-env
    # Non-interactive (no zenity needed):
    #   arcteto-env --name study --tty 2 --user study --dns youtube.com,tiktok.com --apps "zen affine"
    #
    # Every environment gets:
    #   - a TTY with autologin (to the isolated user or to the main user)
    #   - optional separate user (UID 10xx, input/seat groups for mouse/keyboard)
    #   - optional filtered DNS via a per-environment dnsmasq + nftables redirect
    #   - a Hyprland config with the requested autostart apps
    #   - optional wallpaper directory

    set -l NAME study
    set -l TTY 2
    set -l USERNAME ""
    set -l DNS_BLOCK ""
    set -l APPS ""
    set -l WALLPAPER_DIR ""
    set -l CLONE_FROM ""
    set -l KILL_PROCS ""
    set -l SHARE_PATHS ""   # colon-separated host:guest mounts (bindfs map to USERNAME)
    set -l APPARMOR_DENY "" # comma-separated binaries to deny via AppArmor
    set -l ISOLATED 1  # create separate user by default

    # Parse flags
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --name
                set NAME $argv[(math $i + 1)]; set i (math $i + 1)
            case --tty
                set TTY $argv[(math $i + 1)]; set i (math $i + 1)
            case --user
                set USERNAME $argv[(math $i + 1)]; set i (math $i + 1)
            case --dns
                set DNS_BLOCK $argv[(math $i + 1)]; set i (math $i + 1)
            case --apps
                set APPS $argv[(math $i + 1)]; set i (math $i + 1)
            case --wallpaper
                set WALLPAPER_DIR $argv[(math $i + 1)]; set i (math $i + 1)
            case --clone-from
                set CLONE_FROM $argv[(math $i + 1)]; set i (math $i + 1)
            case --kill
                set KILL_PROCS $argv[(math $i + 1)]; set i (math $i + 1)
            case --share
                set SHARE_PATHS $argv[(math $i + 1)]; set i (math $i + 1)
            case --apparmor-deny
                set APPARMOR_DENY $argv[(math $i + 1)]; set i (math $i + 1)
            case --no-user
                set ISOLATED 0
            case '*'
                echo "Unknown arg: $argv[$i]" >&2
                return 1
        end
        set i (math $i + 1)
    end

    # --- Visual helpers (zenity if available, else CLI) ---
    function _env_msg
        if command -v zenity >/dev/null 2>&1
            zenity --info --title "Arcteto Env" --text "$argv[1]" --width 420 2>/dev/null
        else
            echo "Arcteto Env: $argv[1]"
        end
    end
    function _env_confirm
        if command -v zenity >/dev/null 2>&1
            zenity --question --title "Arcteto Env" --text "$argv[1]" --width 420 2>/dev/null
            return $status
        else
            read -P "Arcteto Env: $argv[1] [y/N] " -l a; test "$a" = y; and return 0; or return 1
        end
    end
    function _env_entry
        if command -v zenity >/dev/null 2>&1
            zenity --entry --title "Arcteto Env" --text "$argv[1]" --entry-text "$argv[2]" --width 420 2>/dev/null
        else
            echo -n "Arcteto Env: $argv[1] ($argv[2]): "; read -l v; test -n "$v"; and echo $v; or echo $argv[2]
        end
    end
    function _env_list
        # $argv[1] = text, $argv[2] = comma-separated options, $argv[3] = default
        if command -v zenity >/dev/null 2>&1
            zenity --entry --title "Arcteto Env" --text "$argv[1]\n(Opciones: $argv[2])" --entry-text "$argv[3]" --width 420 2>/dev/null
        else
            echo -n "Arcteto Env: $argv[1] ($argv[3]): "; read -l v; test -n "$v"; and echo $v; or echo $argv[3]
        end
    end

    # Interactive prompts if not provided via flags
    if test -z "$argv[1]" -o (count $argv) -eq 0
        _env_confirm "Crear un entorno aislado en Arcteto?\n\nSe generará un TTY con autologin, usuario opcional, DNS filtrado opcional y apps de autostart."; or return 0

        set NAME (_env_entry "Nombre del entorno (study, streaming, gaming, work...):" $NAME)
        set TTY (_env_entry "TTY a usar (2-6):" $TTY)
        set USERNAME (_env_entry "Usuario aislado (dejar vacío para usar el usuario principal):" $USERNAME)
        set DNS_BLOCK (_env_list "Dominios a bloquear en el DNS (separados por coma, ej: youtube.com,tiktok.com):" "youtube.com,reddit.com,x.com,twitter.com,tiktok.com" "")
        set APPS (_env_entry "Apps de autostart (separadas por espacio, ej: zen affine):" $APPS)
        set WALLPAPER_DIR (_env_entry "Directorio de wallpapers (opcional):" $WALLPAPER_DIR)
        set CLONE_FROM (_env_entry "Clonar config desde otro usuario (dejar vacío para no clonar):" $CLONE_FROM)
        set KILL_PROCS (_env_entry "Procesos a matar si aparecen (ej: steam,lutris,wine; vacío = ninguno):" $KILL_PROCS)
    end

    # If no isolated user specified, use the calling user for autologin
    if test -z "$USERNAME"
        set USERNAME (whoami)
        set ISOLATED 0
    end

    set -l DNS_PORT (math 5335 + $TTY)  # unique port per environment
    set -l AGENT_USER (whoami)

    _env_msg "Creando entorno '$NAME' en TTY$TTY\nUsuario: $USERNAME\nDNS bloqueado: "(test -n "$DNS_BLOCK"; and echo "$DNS_BLOCK"; or echo "ninguno")"\nApps: "(test -n "$APPS"; and echo "$APPS"; or echo "ninguna")""

    # --- 1. Create isolated user if requested ---
    if test $ISOLATED -eq 1
        if not id -u $USERNAME >/dev/null 2>&1
            sudo useradd -m -s /bin/fish $USERNAME
        end
        sudo mkdir -p /home/$USERNAME/.local/state/focuslock
        sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.local/state/focuslock
        sudo usermod -aG input,video,seat,tty $USERNAME
        sudo systemctl enable --now seatd 2>/dev/null
    end

    # --- 1b. Clone config from another user (so the env "starts as you") ---
    if test -n "$CLONE_FROM"
        _env_msg "Clonando config de '$CLONE_FROM' a '$USERNAME'..."
        sudo mkdir -p /home/$USERNAME/.config /home/$USERNAME/.local /home/$USERNAME/.cache
        if not test -e /home/$USERNAME/.config/hypr
            sudo cp -r /home/$CLONE_FROM/.config/* /home/$USERNAME/.config/ 2>/dev/null
        end
        if not test -e /home/$USERNAME/.local/state
            sudo cp -r /home/$CLONE_FROM/.local/* /home/$USERNAME/.local/ 2>/dev/null
        end
        # Remove any focuslock engage/unlock binds from the cloned config (the agent lock is separate)
        sudo sed -i '/focuslock.sh/d; /focusunlock.sh/d' /home/$USERNAME/.config/hypr/hyprland.conf 2>/dev/null
        sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.config /home/$USERNAME/.local /home/$USERNAME/.cache
    end

    # --- 2. Filtered DNS (per-environment dnsmasq + nftables) ---
    if test -n "$DNS_BLOCK"
        set -l STUDY_UID (id -u $USERNAME)
        set -l dnsmasq_conf "/etc/dnsmasq-$NAME.conf"
        set -l dnsmasq_svc "/etc/systemd/system/dnsmasq-$NAME.service"
        set -l nft_conf "/etc/nftables-$NAME.conf"

        # Build address= lines
        set -l addr_lines ""
        for d in (string split "," $DNS_BLOCK)
            set d (string trim $d)
            test -n "$d"; and set addr_lines "$addr_lines\naddress=/$d/0.0.0.0"
        end

        echo "port=$DNS_PORT
listen-address=127.0.0.1
bind-interfaces
no-resolv
server=1.1.1.1$addr_lines
address=/dns.google/0.0.0.0
address=/cloudflare-dns.com/0.0.0.0
address=/dns.quad9.net/0.0.0.0" | sudo tee $dnsmasq_conf >/dev/null

        echo "[Unit]
Description=Arcteto Env ($NAME) DNSmasq
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/usr/bin/bash -c "pkill -f \"dnsmasq.*$DNS_PORT\" 2>/dev/null || true"
ExecStart=/usr/bin/dnsmasq -k -C $dnsmasq_conf
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target" | sudo tee $dnsmasq_svc >/dev/null

        echo "table inet $NAME;
delete table inet $NAME;

table inet $NAME {
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
}" | sudo tee $nft_conf >/dev/null

        sudo nft -f $nft_conf
        if not grep -q "include \"$nft_conf\"" /etc/nftables.conf 2>/dev/null
            echo "include \"$nft_conf\"" | sudo tee -a /etc/nftables.conf >/dev/null
        end
        sudo systemctl enable --now $dnsmasq_svc
    end

    # --- 3. Hyprland config with autostart apps ---
    set -l HL_DIR /home/$USERNAME/.config/hypr
    sudo mkdir -p $HL_DIR
    set -l exec_lines ""
    for app in (string split " " $APPS)
        set app (string trim $app)
        test -n "$app"; and set exec_lines "$exec_lines\nexec-once = $app"
    end
    if test -n "$WALLPAPER_DIR"
        set exec_lines "$exec_lines\nexec-once = noctalia -d"
    end
    echo "# Arcteto environment: $NAME (generated by arcteto-env)
# Autostart apps:
$exec_lines

# Base config (edit as needed)
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store" | sudo tee $HL_DIR/hyprland.conf >/dev/null
    sudo chown -R $USERNAME:$USERNAME $HL_DIR

    # --- 4. TTY autologin ---
    sudo mkdir -p /etc/systemd/system/getty@tty$TTY.service.d
    echo "[Service]
ExecStart=
ExecStart=-/usr/bin/agetty -a $USERNAME --noclear %I \$TERM" | sudo tee /etc/systemd/system/getty@tty$TTY.service.d/override.conf >/dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart getty@tty$TTY

    # --- 5. Watchdog: kill distraction processes in this environment's session ---
    if test -n "$KILL_PROCS"
        echo "#!/usr/bin/env bash
# Arcteto Env ($NAME) watchdog — kills distraction processes in the session.
while true; do" | sudo tee /usr/local/bin/arcteto-$NAME-watchdog >/dev/null
        for p in (string split "," $KILL_PROCS)
            set p (string trim $p)
            test -n "$p"; and echo "    pkill -u $USERNAME -f '$p' 2>/dev/null" | sudo tee -a /usr/local/bin/arcteto-$NAME-watchdog >/dev/null
        end
        echo "    sleep 5
done" | sudo tee -a /usr/local/bin/arcteto-$NAME-watchdog >/dev/null
        sudo chmod 755 /usr/local/bin/arcteto-$NAME-watchdog

        echo "[Unit]
Description=Arcteto Env ($NAME) watchdog (kills $KILL_PROCS)
After=graphical.target

[Service]
Type=simple
ExecStart=/usr/local/bin/arcteto-$NAME-watchdog
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/arcteto-$NAME-watchdog.service >/dev/null
        sudo systemctl enable --now arcteto-$NAME-watchdog.service
    end

    # --- 6. Shared paths via bindfs (host files appear owned by USERNAME, writable) ---
    if test -n "$SHARE_PATHS"
        # ponytail: ephemeral mount, no .mount unit (user said env is discardable)
        if not command -v bindfs >/dev/null 2>&1
            sudo pacman -S --noconfirm bindfs 2>/dev/null; or _env_msg "bindfs no disponible, instalalo para --share"
        end
        set -l HOST_UID (id -u (whoami))
        set -l GUEST_UID (id -u $USERNAME)
        for spec in (string split ":" $SHARE_PATHS)
            set -l parts (string split "," $spec)
            set -l host $parts[1]
            set -l guest $parts[2]
            test -z "$guest"; and set guest "/home/$USERNAME/share/(basename $host)"
            sudo mkdir -p $host $guest
            sudo bindfs --map=$HOST_UID/$GUEST_UID:@$HOST_UID/@$GUEST_UID $host $guest
        end
    end

    # --- 7. AppArmor deny profiles for distraction binaries ---
    if test -n "$APPARMOR_DENY"
        for bin in (string split "," $APPARMOR_DENY)
            set bin (string trim $bin)
            test -z "$bin"; and continue
            set -l path (command -v $bin 2>/dev/null; or echo "/usr/bin/$bin")
            echo "# AppArmor deny profile for $bin (Arcteto env $NAME)
$path {
    deny /** w,
}" | sudo tee /etc/apparmor.d/arcteto-$NAME-$bin >/dev/null
            sudo apparmor_parser -r /etc/apparmor.d/arcteto-$NAME-$bin 2>/dev/null
        end
    end

    set -l clone_msg (test -n "$CLONE_FROM"; and echo "Config clonada de: $CLONE_FROM"; or echo "")
    set -l kill_msg (test -n "$KILL_PROCS"; and echo "Watchdog mata: $KILL_PROCS"; or echo "")
    set -l dns_msg (test -n "$DNS_BLOCK"; and echo "filtrado en :$DNS_PORT"; or echo "sin filtro")
    set -l apps_msg (test -n "$APPS"; and echo "$APPS"; or echo "ninguna")
    _env_msg "Entorno '$NAME' creado.

TTY: $TTY (autologin: $USERNAME)
DNS: $dns_msg
Apps: $apps_msg
$clone_msg
$kill_msg

Para entrar: Ctrl+Alt+F$TTY"
end
