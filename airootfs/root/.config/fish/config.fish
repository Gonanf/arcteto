LC_ALL=es_AR.UTF-8 xdg-user-dirs-update --force
if uwsm check may-start && uwsm select
    exec uwsm start default
end
