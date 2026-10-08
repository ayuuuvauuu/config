tmux rename-window "proxy"

tun2proxy-bin --setup \
  --proxy http://192.168.49.1:8000 \
  --bypass 192.168.49.1 \
  --dns virtual \
  --max-sessions 2048
