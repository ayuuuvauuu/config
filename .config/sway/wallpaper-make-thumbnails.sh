rm -rf ~/.cache/rofi-thumbs
mkdir -p ~/.cache/rofi-thumbs
cd ~/Pictures/wallpapers || exit 1

export OUTDIR="$HOME/.cache/rofi-thumbs"

find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 |
  parallel -0 -j+0 --bar '
    img={}
    name=$(basename "$img")
    ffmpeg -y -loglevel error -i "$img" -vf "scale=256:256:force_original_aspect_ratio=decrease" "$OUTDIR/$name"
  '
