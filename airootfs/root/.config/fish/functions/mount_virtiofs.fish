function mount_virtiofs
    mkdir ~/host0
    sudo mount -t 9p -o trans=virtio,version=9p2000.L host0 ~/host0
    copy_new
end
