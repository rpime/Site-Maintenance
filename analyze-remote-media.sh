#!/usr/bin/env bash

set -e

# Prompt user for domain selection
declare -A DOMAINS=(
  [1]="thejubileebible.org"
  [2]="stendalministries.com"
  [3]="cpcsociety.ca"
  [4]="bibliadeljubileo.org"
)

echo "Select a domain to analyze remote media:"
for i in "${!DOMAINS[@]}"; do
  echo "$i. ${DOMAINS[$i]}"
done

read -rp "Enter the number of the domain (1-${#DOMAINS[@]}): " SELECTED
DOMAIN="${DOMAINS[$SELECTED]}"

if [[ -z "$DOMAIN" ]]; then
  echo "❌ Invalid selection. Aborting."
  exit 1
fi

REMOTE_USER="jubilee"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")

# Set correct remote base directory
if [ "$DOMAIN" = "thejubileebible.org" ]; then
  REMOTE_BASE="\$HOME/public_html"
else
  REMOTE_BASE="\$HOME/$DOMAIN"
fi

REMOTE_UPLOADS="$REMOTE_BASE/wp-content/uploads"
TMP_REMOTE="/tmp/media-analysis-$DOMAIN-$TIMESTAMP"
TMP_LOCAL="$HOME/git/site-maint/media-audit/$DOMAIN/$TIMESTAMP"
LOG_FILE="$HOME/git/site-maint/media-audit/$DOMAIN/deletion.log"

echo "🔐 Connecting to remote server..."

# Prepare local audit folder
mkdir -p "$TMP_LOCAL"

# Cleanup old audits (>360 days) and log them
mkdir -p "$(dirname "$LOG_FILE")"
find "$HOME/git/site-maint/media-audit/$DOMAIN/" -maxdepth 1 -type d -name "20*" -mtime +360 | while read olddir; do
  echo "🗑️  Deleting old audit: $olddir at $(date)" >> "$LOG_FILE"
  rm -rf "$olddir"
done

# Remote media audit
ssh "$REMOTE_USER" bash <<EOF2
  set -e

  mkdir -p "$TMP_REMOTE"
  cd "$REMOTE_BASE" || exit 1

  echo "🔍 Exporting published content (pages, widgets, posts)..."
  > "$TMP_REMOTE/pages.txt"

  wp post list --post_type=page --post_status=publish --field=ID | while read id; do
    wp post get "\$id" --field=post_content >> "$TMP_REMOTE/pages.txt"
  done

  # Future: Include posts and widget content
  # wp post list --post_type=post --post_status=publish --field=ID | while read id; do
  #   wp post get "\$id" --field=post_content >> "$TMP_REMOTE/pages.txt"
  # done

  echo "🎨 Exporting CSS references..."
  find wp-content -type f -name '*.css' -exec cat {} + >> "$TMP_REMOTE/pages.txt" 2>/dev/null

  echo "🖼  Cataloging all images in uploads..."
  find "$REMOTE_UPLOADS" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    > "$TMP_REMOTE/all-images.txt"

  echo "🔗 Detecting used images..."
  sed -E -n 's/.*[\("\'''']([^"\'''')]+\.(jpg|jpeg|png|webp)).*/\1/p' "$TMP_REMOTE/pages.txt" | sort -u > "$TMP_REMOTE/used-urls.txt"

  echo "🗑  Detecting unused images..."
  awk -F/ '{print \$NF}' "$TMP_REMOTE/used-urls.txt" > "$TMP_REMOTE/used-filenames.txt"
  awk -F/ '{print \$NF}' "$TMP_REMOTE/all-images.txt" > "$TMP_REMOTE/all-filenames.txt"

  grep -Fxf "$TMP_REMOTE/used-filenames.txt" "$TMP_REMOTE/all-filenames.txt" > "$TMP_REMOTE/used-images.txt"
  grep -Fvxf "$TMP_REMOTE/used-filenames.txt" "$TMP_REMOTE/all-filenames.txt" > "$TMP_REMOTE/unused-images.txt"
EOF2

echo "⬇️  Downloading results to $TMP_LOCAL..."
scp -P 2222 jubilee:"$TMP_REMOTE/used-images.txt" "$TMP_LOCAL/used-images.txt"
scp -P 2222 jubilee:"$TMP_REMOTE/unused-images.txt" "$TMP_LOCAL/unused-images.txt"

echo "📦 Bundling into ZIP archive..."
cd "$HOME/git/site-maint/media-audit/$DOMAIN"
zip -rq "$TIMESTAMP.zip" "$TIMESTAMP"

echo "✅ Done. Check:"
echo "  - $TMP_LOCAL/used-images.txt"
echo "  - $TMP_LOCAL/unused-images.txt"
echo "  - $HOME/git/site-maint/media-audit/$DOMAIN/$TIMESTAMP.zip"
echo "  - $LOG_FILE"
