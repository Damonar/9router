#!/bin/sh
set -e

BACKUP_DIR="/tmp/backup"
DB_PATH="$DATA_DIR/db/data.sqlite"

if [ -n "$HF_BACKUP_TOKEN" ] && [ -n "$HF_BACKUP_REPO" ]; then
  echo "[backup] cloning backup repo..."
  git clone "https://${HF_USERNAME}:${HF_BACKUP_TOKEN}@huggingface.co/datasets/${HF_BACKUP_REPO}" "$BACKUP_DIR" 2>/dev/null || mkdir -p "$BACKUP_DIR"
  cd "$BACKUP_DIR"
  git config user.email "bot@bot.com"
  git config user.name "backup-bot"
  cd /app

  if [ -f "$BACKUP_DIR/data.sqlite" ]; then
    mkdir -p "$DATA_DIR/db"
    cp "$BACKUP_DIR/data.sqlite" "$DB_PATH"
    echo "[backup] restored last backup"
  else
    echo "[backup] no previous backup found, starting fresh"
  fi

  ( while true; do
      sleep 300
      if [ -f "$DB_PATH" ]; then
        cp "$DB_PATH" "$BACKUP_DIR/data.sqlite"
        cd "$BACKUP_DIR"
        git add data.sqlite
        git commit -m "auto backup" >/dev/null 2>&1 || true
        git push >/dev/null 2>&1 || true
        cd /app
      fi
    done ) &
fi

exec node custom-server.js
