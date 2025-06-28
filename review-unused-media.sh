#!/bin/bash

set -e

DOMAIN="$1"
AUDIT_ROOT="$HOME/media-audit/$DOMAIN"
LATEST_DIR=$(ls -dt "$AUDIT_ROOT"/20* | head -n 1)

UNUSED="$LATEST_DIR/unused-images.txt"
LOGFILE="$AUDIT_ROOT/deletion.log"
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
REMOTE_UPLOADS="~/public_html/wp-content/uploads"
BACKUP_NAME="unused-images-backup-$TIMESTAMP.zip"

# Correct reference
UNUSED_FILE="$LATEST_DIR/unused-images.txt"

if [ ! -s "$UNUSED_FILE" ]; then
  echo "❌ No unused-images.txt found or it's empty."
  exit 1
fi

echo "🗂  Found unused images list at: $UNUSED"
echo "📋 Previewing files to delete:"
cat "$UNUSED"

read -rp "⚠️  Proceed with deletion? (y = delete, b = backup then delete, N = abort): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "b" ]]; then
  echo "❌ Aborted."
  exit 1
fi

if [[ "$CONFIRM" == "b" ]]; then
  echo "💾 Backing up files to ZIP on server before deletion..."
  scp -P 2222 "$UNUSED" jubilee:/tmp/unused-list.txt

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
scp -P 2222 "$UNUSED" jubilee:/tmp/unused-list.txt

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
done < "$UNUSED"

echo "✅ Deletion complete. Log saved to: $LOGFILE"
