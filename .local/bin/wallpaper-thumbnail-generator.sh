# 1. Clear existing thumbnail cache
rm -rf ~/.cache/rofi-thumbs
mkdir -p ~/.cache/rofi-thumbs

# 2. Go to wallpaper directory
cd ~/Pictures/wallpapers || exit 1

# 3. Generate thumbnails with aspect ratio preserved (256px max)
find . -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 |
while IFS= read -r -d '' img; do
    name="$(basename "$img")"
    ffmpeg -y -loglevel error \
        -i "$img" \
        -vf "scale=256:256:force_original_aspect_ratio=decrease" \
        "$HOME/.cache/rofi-thumbs/$name"
done
