[x] Añadir ROCM-SMI
[x] Añadir vulkan-radeon / vulkan-intel
[x] Añadir intel-gpu-tools
[x] Iniciar el Keyring, popular, refrescar y descargarlo
[x] Habilitar systemd-timesyncd y añadir servidores NTP en la config (/etc/systemd/timesyncd.conf)
[x] Actualizar el .config de noctalia shell e hyprland de este proyecto con los mios actuales
[x] Añadir hyprpicker
[x] Añadir cliphist
[x] Añadir flameshot
[x] Limitar la cantidad de snapshots que puede tener /home y /root
[x] Hacer README
[x] start_emu tiene problemas con que no tiene acceso por defecto a /tmp/temp.raw y /usr/share/OVMF/x64/OVMF_VARS.4m.fd
[x] Separar custom_packages entre los de repositorios y los de AUR
[x] Modificar build-custom-packages para utilizar el listado de packetes AUR e instalarlos
[x] Copiar custom_db en airootfs/local/repo
[x] Error pacstrap: file not found /etc/vconsole.conf
[x] Symlink /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf to /etc/fonts/conf.d/
[x] Error: Mount point /boot which backs the random seed file is world accesible, which is a security hole
[x] Error: Failed to enable unit systemd-resolver.service
[x] Error: Failed to enable units after sshd service
[x] Error: Permission denied /home/(user)/.config, the user must own its own config file
[x] Add kservice as a package
[x] Get wallpapers at build time, into ./wallpapers
[x] Pass the wallwapers both to root and user
[x] Add archlinux-xdg-menu as a package
[x] Export XDG_MENU_PREFIX=arch- (Or run XDG_MENU_PREFIX=arch- kbuildsycoca6 at startup)
[x] Create aliases for common commands
[x] Add qt6-websockets (AAUR)
[x] Add kbuildsycoca6

# Notas sobre las correcciones:
# 16: Agregado hook consolefont a mkinitcpio.conf.d/archiso.conf y FONT=ter-v16n a vconsole.conf
# 17: Agregado symlink en customize_airootfs.sh
# 18: Agregado chmod 700 /boot en customize_airootfs.sh
# 19: El servicio correcto es systemd-resolved.service (no resolver), ya está configurado
# 20: Los servicios systemd-resolved y sshd ya están correctamente configurados en multi-user.target.wants
# 21: Corregido permisos con chown -R teto:users y chmod 755 en customize_airootfs.sh
# 22-29: Agregados paquetes, wallpapers, aliases, y configuraciones correspondientes
