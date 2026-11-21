# aria2c completions, converted from the Bash completion.

# Options which take a value.  This keeps Fish from suggesting unrelated
# options after these flags.
set -l aria2c_value_options \
    timeout connect-timeout max-tries auto-save-interval log dir out split \
    referer lowest-speed-limit piece-length max-overall-download-limit max-download-limit \
    file-allocation no-file-allocation-limit conf-path stop summary-interval log-level \
    console-log-level uri-selector server-stat-timeout server-stat-if server-stat-of \
    max-file-not-found event-poll rpc-listen-port rpc-user rpc-passwd rpc-max-request-size \
    rpc-certificate rpc-private-key on-download-start on-download-pause on-download-stop \
    on-download-complete on-download-error interface multiple-interface max-resume-failure-tries \
    save-session max-connection-per-server min-split-size max-download-result retry-wait \
    async-dns-server stream-piece-selector checksum stop-with-process disk-cache gid \
    save-session-interval rpc-secret dscp rlimit-nofile min-tls-version socket-recv-buffer-size \
    max-mmap-limit ftp-user ftp-passwd ftp-type ssh-host-key-md http-user http-passwd user-agent \
    load-cookies save-cookies header certificate private-key ca-certificate http-proxy https-proxy \
    ftp-proxy all-proxy no-proxy proxy-method http-proxy-user http-proxy-passwd https-proxy-user \
    https-proxy-passwd ftp-proxy-user ftp-proxy-passwd all-proxy-user all-proxy-passwd \
    max-overall-upload-limit max-upload-limit listen-port dht-listen-port dht-entry-point \
    dht-file-path dht-listen-addr6 dht-entry-point6 dht-file-path6 bt-min-crypto-level \
    bt-request-peer-speed-limit bt-max-open-files bt-max-peers bt-external-ip index-out \
    bt-tracker-interval bt-stop-timeout bt-prioritize-piece bt-tracker bt-exclude-tracker \
    bt-lpd-interface bt-tracker-timeout bt-tracker-connect-timeout dht-message-timeout \
    on-bt-download-complete metalink-version metalink-language metalink-os metalink-location \
    metalink-preferred-protocol

for opt in $aria2c_value_options
    complete -c aria2c -l $opt -r
end

# Boolean and valueless options.
set -l aria2c_flags \
    version help daemon quiet async-dns no-netrc deferred-input optimize-concurrent-downloads \
    force-sequential auto-file-renaming parameterized-uri allow-piece-length-change no-conf \
    remote-time enable-rpc rpc-listen-all rpc-allow-origin-all rpc-secure rpc-save-upload-metadata \
    dry-run reuse-uri conditional-get enable-async-dns6 show-console-readout truncate-console-readout \
    pause hash-check-only enable-mmap force-save save-not-found enable-color stderr \
    keep-unfinished-download-result ftp-pasv ftp-reuse-connection enable-http-keep-alive \
    enable-http-pipelining check-certificate use-head http-auth-challenge http-no-cache \
    http-accept-gzip content-disposition-default-utf8 no-want-digest-header show-files \
    continue allow-overwrite realtime-chunk-checksum check-integrity \
    follow-torrent enable-peer-exchange enable-dht enable-dht6 bt-require-crypto bt-seed-unverified \
    bt-hash-check-seed bt-save-metadata bt-metadata-only bt-enable-lpd bt-remove-unselected-file \
    bt-detach-seed-only bt-force-encryption bt-enable-hook-after-hash-check bt-load-saved-metadata \
    follow-metalink metalink-enable-unique-protocol

for opt in $aria2c_flags
    complete -c aria2c -l $opt
    complete -c aria2c -l "$opt=false"
end

# Help categories and the remaining options which accept values or switches.
complete -c aria2c -l help -a '#basic #advanced #http #https #ftp #metalink #bittorrent #cookie #hook #file #rpc #checksum #experimental #deprecated #help #all'
complete -c aria2c -l input-file -r
complete -c aria2c -l torrent-file -r -F
complete -c aria2c -l metalink-file -r -F
complete -c aria2c -l metalink-base-uri -r
complete -c aria2c -l select-file -r
complete -c aria2c -l seed-time -r
complete -c aria2c -l seed-ratio -r
complete -c aria2c -l peer-id-prefix -r
complete -c aria2c -l peer-agent -r
complete -c aria2c -l dht-listen-port -r

# Enumerated values from the Bash completion.
complete -c aria2c -l ftp-type -a 'binary ascii'
complete -c aria2c -l proxy-method -a 'get tunnel'
complete -c aria2c -l metalink-preferred-protocol -a 'http https ftp none'
complete -c aria2c -l bt-min-crypto-level -a 'plain arc4'
complete -c aria2c -l follow-metalink -a 'true mem false'
complete -c aria2c -l file-allocation -a 'none prealloc trunc falloc'
complete -c aria2c -l log-level -a 'debug info notice warn error'
complete -c aria2c -l console-log-level -a 'debug info notice warn error'
complete -c aria2c -l uri-selector -a 'inorder feedback adaptive'
complete -c aria2c -l event-poll -a 'epoll poll select'
complete -c aria2c -l follow-torrent -a 'true mem false'
complete -c aria2c -l stream-piece-selector -a 'default inorder random geom'
complete -c aria2c -l download-result -a 'default full hide'
complete -c aria2c -l min-tls-version -a 'TLSv1.1 TLSv1.2 TLSv1.3'

# Use directories for --dir and matching files for input/torrent/metalink files.
complete -c aria2c -l dir -a '(__fish_complete_directories)'
complete -c aria2c -l input-file -a '(__fish_complete_path)'
complete -c aria2c -l torrent-file -a '(__fish_complete_path -f -a "*.torrent")'
complete -c aria2c -l metalink-file -a '(__fish_complete_path -f -a "*.meta4" "*.metalink")'

# Positional arguments: URLs or URL-list/torrent/metalink files.
complete -c aria2c -a '(__fish_complete_path -f -a "*.torrent" "*.meta4" "*.metalink" "*.text" "*.txt" "*.list" "*.lst")'
