#!/bin/bash

set -e

DOMAIN="$1"
REMOTE_USER="jubilee"

if [ "$DOMAIN" = "thejubileebible.org" ]; then
  REMOTE_BASE="\$HOME/public_html"
else
  REMOTE_BASE="\$HOME/$DOMAIN"
fi

REMOTE_UPLOADS="\$REMOTE_BASE/wp-content/uploads"
TMP_REMOTE="/tmp/media-analysis-$DOMAIN"
TMP_LOCAL="$HOME/media-audit/$DOMAIN"

echo "🔐 Connecting to remote server..."

# Prepare domain-specific folder locally
mkdir -p "$TMP_LOCAL"

# Run analysis remotely
ssh "$REMOTE_USER" bash <<EOF2
  set -e

  mkdir -p "$TMP_REMOTE"
  cd "$REMOTE_BASE" || exit 1

  echo "🔍 Exporting published content (pages, widgets, posts)..."
  > "$TMP_REMOTE/pages.txt"

  wp post list --post_type=page --post_status=publish --field=ID | while read id; do
    wp post get "\$id" --field=post_content >> "$TMP_REMOTE/pages.txt"
  done

  # Future: Uncomment to include posts and widgets
  # wp post list --post_type=post --post_status=publish --field=ID | while read id; do
  #   wp post get "\$id" --field=post_content >> "$TMP_REMOTE/pages.txt"
  # done

  echo "🎨 Exporting CSS references..."
  find wp-content -type f -name '*.css' -exec cat {} + >> "$TMP_REMOTE/pages.txt"

  echo "🖼  Cataloging all images in uploads..."
  find "$REMOTE_UPLOADS" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    > "$TMP_REMOTE/all-images.txt"

  echo "🔗 Detecting used images..."
  grep -oE '[^"]+\.(jpg|jpeg|png|webp)' "$TMP_REMOTE/pages.txt" | sort -u > "$TMP_REMOTE/used-urls.txt"

  echo "🗑  Detecting unused images..."
  grep -Fvf "$TMP_REMOTE/used-urls.txt" "$TMP_REMOTE/all-images.txt" > "$TMP_REMOTE/unused-images.txt"
  grep -Ff  "$TMP_REMOTE/used-urls.txt" "$TMP_REMOTE/all-images.txt" > "$TMP_REMOTE/used-images.txt"
EOF2

echo "⬇️  Downloading results to $TMP_LOCAL..."
scp -P 2222 jubilee:"$TMP_REMOTE/used-images.txt" "$TMP_LOCAL/used-images.txt"
scp -P 2222 jubilee:"$TMP_REMOTE/unused-images.txt" "$TMP_LOCAL/unused-images.txt"

echo "✅ Done. Check:"
echo "  - $TMP_LOCAL/used-images.txt"
echo "  - $TMP_LOCAL/unused-images.txt"
