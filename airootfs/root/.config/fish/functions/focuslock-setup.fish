function focuslock-setup
    # FocusLock study environment — convenience wrapper around arcteto-env.
    # Creates the isolated "study" user on TTY2 with filtered DNS (YouTube,
    # TikTok, Reddit, X) and the study apps (zen + affine). For a generic
    # environment, use `arcteto-env` directly.
    arcteto-env --name study --tty 2 --user study \
        --dns "youtube.com,reddit.com,x.com,twitter.com,tiktok.com,www.tiktok.com,vm.tiktok.com,tiktokcdn.com,byteoversea.com" \
        --apps "zen-browser --new-instance https://www.coursera.org/programs https://youtube.com/playlist?list=PLtepJ-8bQVrfBpEKGst92eS_KyDcgATn6 affine"
end
