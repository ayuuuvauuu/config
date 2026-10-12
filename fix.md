# System fix list (12-agent audit, 2026-10-12)

Issue + proposed fix only. Nothing applied yet.

## Critical

### Committed API key in `codex-zen`
- Issue: `.local/bin/codex-zen:11` hardcodes a real `sk-...` key, exported at `:185`. Committed to git, world-readable.
- Fix: rotate the key at the provider, then `git rm` the secret / purge history (`git filter-repo`), add secret to `.gitignore`.

### Broken audio service causes sudo lockouts
- Issue: `fix-audio-powersave.service` can't write sysfs as user unit (`Permission denied`), burns sudo retries → `pam_faillock` lockout. `fix-firefox-audio.service` duplicates it.
- Fix: `systemctl --user disable --now fix-audio-powersave.service fix-firefox-audio.service`; fold the working bits into the existing wireplumber `50-alsa-suspend.conf` layer, delete the third (`suspend-node.lua` or the services).

## Config errors

### `foot.ini` has no section header
- Issue: `.config/foot/foot.ini:4-11` keys (`term=`, `font*`, `alpha=`) sit before any `[main]` header → foot errors; `alpha=` is under `[colors-dark]` instead of `[colors]`.
- Fix: add `[main]` at top, move `alpha=` under `[colors]`, verify with `foot --check-config`.

### `mpv.conf` extractor line is malformed
- Issue: `.config/mpv/mpv.conf:1` appends `--extractor-args=...` onto the `ytdl-format=` line; config syntax is bare `key=value`, so format selection gets garbage and the arg never applies. Also `profile=gpu-hq` mismatches `vo=gpu-next` (want `profile=high-quality`).
- Fix: split into separate `ytdl-raw-options=` line; set `profile=high-quality`; drop redundant `interpolation=` / `cache-secs`+`demuxer-readahead-secs` dup.

### `powertop` fish function is broken
- Issue: `.config/fish/functions/powertop.fish:2` single-quotes `sh -c 'powertop "$@"'` so args never expand.
- Fix: rewrite as `sudo powertop $argv` directly, no `sh -c` wrapper.

### Invalid git email
- Issue: `~/.gitconfig:2` sets `email = ayush` (no `@`); hidden because repo-local config masks it.
- Fix: set a real global `user.email` + `user.name`.

## Shell startup + prompt

### Fish bloat and prompt leaks
- Issue: `config.fish` sets `TERM` twice, re-prepends `PATH` 8× per shell, runs `zoxide init` for non-interactive shells; `hydro` leaks ~90 `_hydro_git_<PID>` universal vars and runs `git fetch` per prompt.
- Fix: single `TERM` (or unset), guarded `fish_add_path`, gate `zoxide` on `status is-interactive`, drop hydro's per-PID universal vars / prompt fetch.

## Git churn

### Cache/history files tracked
- Issue: `.config/cmus/lib.pl`, `search-history`, `btop.conf` (rewritten on exit via `save_config_on_exit`), per-game Lutris `*.yml`, `Desktop/*.desktop` all churn in `git status`.
- Fix: extend `.gitignore` exclusions, `git rm --cached` the caches; decide if playlists + game ymles stay tracked.

## Scripts

### Shebangs + sudo redirect
- Issue: `pdanet-proxy.sh:1`, `wallpaper-thumbnail-generator.sh:1` lack shebangs; `idle-power:27` does `sudo … > file` (redirect unprivileged); `apply-pacman-wget:12` uses `A && B || C`.
- Fix: add `#!/bin/bash`, use `sudo tee` for the redirect, rewrite as `if/else`.

## Permissions

### Loose perms
- Issue: `~/.ssh` is `755` (want `700`); `.gnupg/public-keys.d` `750` and `common.conf` `640` grant group access.
- Fix: `chmod 700 ~/.ssh ~/.gnupg/public-keys.d; chmod 600 ~/.gnupg/common.conf`.

## Docs drift

### README stale spots
- Issue: limine template lacks live `usbcore.quirks=30c9:0069:b`; `tlp.conf` doc says `SOUND_POWER_SAVE_ON_BAT=1` vs live `10`; `logind.conf` doc omits `HandlePowerKey=hibernate`; package table lists uninstalled/absent pkgs (`vlc`, `nitrogen`, `auto-cpufreq` service runs but pkg missing).
- Fix: sync the four snippets; correct package names (`tumbler`, node 26); note `auto-cpufreq` install source.

## Disk

### `/` at 75%, 11 orphans
- Issue: `/` 22G/31G used; `~/.cache/mozilla` 229M + `opencode` 189M; 11 orphans (`gnome-desktop`, `llvm21-libs`, …).
- Fix: clear caches, review orphans with `pacman -Qdt`, then `pacman -Rns` selected ones.

## Udev error in journal

### Missing `usb-power-switch`
- Issue: journal shows udev failing on `ADP1`: `/usr/local/bin/usb-power-switch` missing, so USB/LPMD switching never runs.
- Fix: reinstall the script per README §USB autosuspend, then `udevadm control --reload-rules`.
