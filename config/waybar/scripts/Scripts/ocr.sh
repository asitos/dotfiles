#!/usr/bin/env bash

# 1. Capture the region to a temp file (safer than pipes for debugging)
IMG_TMP=$(mktemp --suffix=.png)
grim -g "$(slurp)" "$IMG_TMP"

# 2. OCR the image and strip extra whitespace
# "tesseract" adds form-feeds; we clean that up.
TEXT=$(tesseract "$IMG_TMP" stdout 2>/dev/null | sed 's/^[ \t]*//;s/[ \t]*$//')

# 3. Clean up the image
rm "$IMG_TMP"

# 4. Check if we actually found text
if [ -z "$TEXT" ]; then
    notify-send -u low "OCR Failed" "No text detected."
    exit 1
fi

# 5. Copy to Clipboard (Force Type)
# We use printf to avoid adding an extra newline at the end
printf "%s" "$TEXT" | wl-copy --type text/plain

# 6. Notify
notify-send -u normal "OCR Copied" "$TEXT"
