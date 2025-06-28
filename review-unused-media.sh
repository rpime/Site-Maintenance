#!/usr/bin/env bash

set -e

DOMAIN="$1"
AUDIT_ROOT="$HOME/media-audit/$DOMAIN"
LATEST_DIR="$AUDIT_ROOT/latest"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
LOGFILE="$AUDIT_ROOT/deletion.log"
REMOTE_UPLOADS="~/public_html/wp-content/uploads"
BACKUP_NAME="unused-images-backup-$TIMESTAMP.zip"

# Resolve the full path or use fallback if readlink -f is unavailable
if command -v greadlink &>/dev/null; then
  UNUSED_FILE=$(greadlink -f "$LATEST_DIR/unused-images.txt") || UNUSED_FILE="$LATEST_DIR/unused-images.txt"
elif command -v readlink &>/dev/null && readlink -f "$LATEST_DIR/unused-images.txt" &>/dev/null; then
  UNUSED_FILE=$(readlink -f "$LATEST_DIR/unused-images.txt")
else
  UNUSED_FILE="$LATEST_DIR/unused-images.txt"
fi

# 🔍 DEBUG block goes HERE — now $UNUSED_FILE is defined
echo "DEBUG: Bash version: $BASH_VERSION"
echo "DEBUG: Resolved UNUSED_FILE: $UNUSED_FILE"
ls -l "$UNUSED_FILE"
file "$UNUSED_FILE"
stat "$UNUSED_FILE"
[[ -s "$UNUSED_FILE" ]] && echo "✅ File is non-empty." || echo "❌ File is empty according to test -s"

if [ ! -s "$UNUSED_FILE" ]; then
  echo "❌ No unused-images.txt found or it's empty."
  exit 1
fi

echo "🗂  Found unused images list at: $UNUSED_FILE"
echo "📋 Previewing files to delete:"
cat "$UNUSED_FILE"

read -rp "⚠️  Proceed with deletion? (y = delete, b = backup then delete, N = abort): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "b" ]]; then
  echo "❌ Aborted."
  exit 1
fi

if [[ "$CONFIRM" == "b" ]]; then
  echo "💾 Backing up files to ZIP on server before deletion..."
  scp -P 2222 "$UNUSED_FILE" jubilee:/tmp/unused-list.txt

  ssh jubilee bash <<EOF2
    set -e
    cd "$REMOTE_UPLOADS"
    mkdir -p /tmp/unused-backup-$TIMESTAMP
    while read -r fname; do
      find . -type f -name "\$fname" -exec cp --parents {} /tmp/unused-backup-$TIMESTAMP/ \;
    done < /tmp/unused-list.txt
    cd /tmp
    zip -rq "$BACKUP_NAME" "unused-backup-$TIMESTAMP"
    rm -rf "unused-backup-$TIMESTAMP" /tmp/unused-list.txt
EOF2
  echo "✅ Backup complete: /tmp/$BACKUP_NAME"
fi

echo "🧹 Deleting unused images..."
scp -P 2222 "$UNUSED_FILE" jubilee:/tmp/unused-list.txt

ssh jubilee bash <<EOF2
  set -e
  while read -r fname; do
    find "$REMOTE_UPLOADS" -type f -name "\$fname" -exec rm -v {} \;
  done < /tmp/unused-list.txt
  rm -f /tmp/unused-list.txt
EOF2

echo "🪵 Logging deletions..."
while read -r fname; do
  echo "$fname deleted on $TIMESTAMP" >> "$LOGFILE"
done < "$UNUSED_FILE"

echo "✅ Deletion complete. Log saved to: $LOGFILE"
