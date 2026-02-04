source ./log.fish
function wait_key
    log Wait "Press any key to continue"
    read -n 1 -s -p ""; or exit 1
    echo ""
end
