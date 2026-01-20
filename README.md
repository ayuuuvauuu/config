## chrome flags
--force-device-scale-factor=1
--disable-gpu-driver-bug-workarounds (in usr/application/chome.destop)
#smooth-scrolling disabled
#ozone-platform-hint wayland
#overlay-scrollbars
#enable-lazy-load-image-for-invisible-pages
#enable-gpu-rasterization
#enable-zero-copy
#enable-unsafe-webgpu
#enable-tab-audio-muting
#enable-parallel-downloading


change the ttl to 65 to make trick isp into thinking that i am not using hotsopt

NOTE: remove all fish.tmp. files form the fish dir to remove all the temporaye enviroment variables
 required Prgrame to install

https://github.com/oddmario/NVIDIA-Ubuntu-Driver-Guide

screensy (to share screen)  https://screensy.marijn.it


put this in sway config file in /etc/sway/config.d/(the config file) see 

https://bbs.archlinux.org/viewtopic.php?id=291201
#screen sharing in wayland

exec --no-startup-id dbus-update-activation-environment --systemd \
   WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway XDG_SESSION_DESKTOP=sway XDG_SESSION_TYPE=wayland
exec --no-startup-id systemctl --user start pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr

for wayland screen recording use gpu-screen-recoder-gtk
for laptpo autocpu freq, powertop ( more search) use h264ify for youtube to use less battery and hardware acc in yt vid
install dysk, dua-cli, astroterm
stwich to g++ 12 for no error in nvim, install arttime :)
use eza insted of ls use zoxide use  use yazi, fd, fzf,rg
install jq (json parser)
sccahe (a cacheing system for rust)
tmux comme u need it
so (its in yout /usr/bin) a tui for stackvoerflwo
GIMP image editor
 nvim (latest version)
 discord
 st (latest form suckless)
 awesome(window-manager or somethign better if avaiable like hyperlnad or i3 also)
 btop(proc-manager)
    pip install i3ipc
 fish (terminal-emulator) and foot
 lynx (the best web browser in the world) 
 jetbarins mono nerd font
 nitrogen
 rofi(app-launcher)
 vlc

GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=0 rd.systemd.show_status=false ipv6.disable=1 vt.global_cursor_default=0"

### curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs 

istall rust, gcc,clang, and jo be hai uska latest version, dont go with build-essential(latest version isstall kiya then also check)
update nodejs for pyright to wofuck


NVIM config 
i have my own config (inspired from nvchad's config)
at https://github.com/ayush-india/.nvim
GOat 
fish key bindings

run fzf_configure_bindings --help

get nvim ppa https://github.com/neovim/neovim/blob/master/INSTALL.md#ubuntu

save new fonts in ~/.local/share/fonts and /usr/share/fonts/ 

use fc-list(alacatry ka config file me hai command) to see if font installed

see aeseome last commands to get to know how i make toucpad gestures working 
#### DECORATIONS
https://github.com/segf00lt/pomo.git isntall this and make simple symbolic link 
`sudo ln -sf /opt/pomodoro/pomo.sh /usr/local/bin/pomo`

lavat, pipes.sh, cboansi, cmatrix, fastfetch , rain.sh(in repo) more coming soon
