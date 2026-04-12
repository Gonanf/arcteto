test -e ~/Descargas; or LC_ALL=es_AR.UTF-8 xdg-user-dirs-update --force

# Set XDG menu prefix for KDE applications
set -gx XDG_MENU_PREFIX arch-

alias ls 'ls --color=auto'
alias ll 'ls -la'
alias l 'ls -lah'
alias .. 'cd ..'
alias ... 'cd ../..'
alias grep 'grep --color=auto'
alias cp 'cp -iv'
alias mv 'mv -iv'
alias rm 'rm -iv'
alias mkdir 'mkdir -pv'
alias df 'df -h'
alias du 'du -h'
alias free 'free -m'
alias update 'sudo pacman -Syu'
alias install 'sudo pacman -S'
alias remove 'sudo pacman -Rns'
alias search 'pacman -Ss'
alias orphans 'pacman -Qdtq'
alias clean 'sudo pacman -Sc'
alias vi nvim
alias vim nvim

if uwsm check may-start && uwsm select
    exec uwsm start default
end
