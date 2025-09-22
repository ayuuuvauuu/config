## st - simple terminal ![st](https://img.shields.io/static/v1?label=st&message=0.9.2&color=blue&style=flat-square)

`st` is a simple terminal emulator for X which [sucks-less](https://git.suckless.org/st/). The following patches have been incorporated in this build.

<details><summary>Click to view</summary>

- [st-alpha](https://st.suckless.org/patches/alpha/st-alpha-20220206-0.8.5.diff) - Allow `st` to have transparency while keeping text opaque.
- [st-anysize](https://st.suckless.org/patches/anysize/st-anysize-20220718-baa9357.diff) - Allows st to resize to any pixel size.
- [st-bold-is-not-bright](https://st.suckless.org/patches/bold-is-not-bright/st-bold-is-not-bright-20190127-3be4cf1.diff) - This patch makes bold text rendered simply as bold, leaving the color unaffected.
- [st-boxdraw](https://st.suckless.org/patches/boxdraw/st-boxdraw_v2-0.8.5.diff) - This patch adds options to render most of the lines/blocks characters without using the font so that they align perfectly regardless of font, size.
- [st-charoffsets](https://st.suckless.org/patches/charoffsets/st-charoffsets-20220311-0.8.5.diff) - This patch allow you to adjust the glyph position, so it doesn't get clipped short.
- [dont-cut-text]() - Allow us to resize terminal window without cutting text.
- [st-dynamic-cursor-color](https://st.suckless.org/patches/dynamic-cursor-color/st-dynamic-cursor-color-0.9.diff) - Swaps the colors of your cursor and the character you're currently on.
- [st-externalpipe](https://st.suckless.org/patches/externalpipe/st-externalpipe-0.8.4.diff) - Reading and writing `st's` screen through a pipe.
- [st-glyph-wide-support-boxdraw](https://st.suckless.org/patches/glyph_wide_support/st-glyph-wide-support-boxdraw-20220411-ef05519.diff) - This patch fixes wide glyphs truncation.
- [st-ligatures-boxdraw](https://st.suckless.org/patches/ligatures/0.9/st-ligatures-boxdraw-20221120-0.9.diff) - Add support for ligatures.
- [st-scrollback](https://st.suckless.org/patches/scrollback/) - Add `scrollback` support to terminal.
- [st-xresources-with-reload-signal](https://st.suckless.org/patches/xresources/) - Allow changing terminal colors,fonts etc. without `recompiling or restarting` `st` from `.xresource` file.
- [st-blinking_cursor](https://st.suckless.org/patches/blinking_cursor/st-blinking_cursor-20211116-2f6e597.diff) - This patch allows the use of a blinking cursor.
- [st-xresources](https://st.suckless.org/patches/xresources/st-xresources-20200604-9ba7ecf.diff) - This patch adds the ability to configure st via `Xresources`. At startup, st will read and apply the resources named in the resources[] array in `config.h`.
- [st-font2](https://st.suckless.org/patches/font2/st-font2-0.8.5.diff) - This patch allows to add spare font besides default. Some glyphs can be not present in default font. For this glyphs st uses font-config and try to find them in font cache first.
- [st-desktopentry](https://st.suckless.org/patches/desktopentry/st-desktopentry-0.8.5.diff) - Creates a desktop-entry for st. This enables to find st in a graphical menu and to display it with a nice icon.
- [st-netwmicon](https://st.suckless.org/patches/netwmicon/st-netwmicon-0.8.5-v2.diff) - Enables to set _NET_WM_ICON with a `png-image`.

</details>

## Features

- Fonts, colors etc. can be configured from `.Xresource` file. No need to `restart or recompile st`.
- Texts don't cut while resizing terminal.
- Support transparency while keeping text opaque. This is controlled by `alpha` variable in `config.def.h` or `.Xresources`.
- Support font ligatures.
- Select `url` from terminal window. Put `st-urlhandler` in your path variable. Use <kbd>alt+u</kbd> to open url and use <kbd>alt+y</kbd> to copy url.
- Dynamic-color cursor support make terminal appealing and easy to follow cursor.
- Support blinking cursor. Blink-rate is managed by `blinktimeout` variable in `config.def.h` or `.Xresource`.
- St opacity can be changed without `restarting` or `recompiling`.
- Support for spare font besides default. If some glyph is not present in default then this `spare` font will be used.
- Create a desktop entry. This enables st in a graphical menu like `rofi`.

## Requirements

In order to build st you need the Xlib header files. `dmenu` and `linkhandler` scripts.

## Installation

```
git clone https://github.com/zootedb0t/st.git
cd st
sudo make install
```

Configuration is done through editing `config.def.h`. Run `make clean` and `sudo make install` to recompile.

Edit `config.mk` to match your local setup (st is installed into
the /usr/local namespace by default).

Afterwards enter the following command to build and install st (if necessary as root):

```
sudo make clean install
```

## Keybindings

Default Keybindings:

<!-- prettier-ignore -->
| Action                | Keys                   |
|-----------------------|------------------------|
| Copy                  | <kbd>ctrl+shift+c</kbd>|
| Paste                 | <kbd>ctrl+shift+v</kbd>|
| Increase transparency | <kbd>alt+s</kbd>       |
| Decrease transparency | <kbd>alt+a</kbd>       |
| Disable transparency  | <kbd>alt+m</kbd>       |
| Open Url              | <kbd>alt+u</kbd>       |
| Copy Url              | <kbd>alt+y</kbd>       |
| Zoom in               | <kbd>alt+.</kbd>       |
| Zoom out              | <kbd>alt+,</kbd>       |

Keybindings are modified by editing `shortcuts` array in `config.def.h`.

```
make clean
sudo make install
```

## Screenshot

![Screenshot_2023-05-01-06-31-42_](https://user-images.githubusercontent.com/62596687/235456160-56baadd5-2099-4ed1-9a84-59f6d9b0c5d6.png)

## Credits

Based on Aurélien APTEL <aurelien dot aptel at gmail dot com> bt source code.
