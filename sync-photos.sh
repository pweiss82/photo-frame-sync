#!/bin/bash
# Sync Google Drive photos to a local slideshow folder, convert HEICs, cleanup, and (re)start feh safely.

###############################################################################
# Configuration
###############################################################################
RAW_DIR="/home/gfd/Pictures/PhotoFrame/Raw"
DISPLAY_DIR="/home/gfd/Pictures/PhotoFrame/Display"

RCLONE_REMOTE="gdrive"
RCLONE_TEAM_DRIVE_ID="0ANrWAw4_0pIuUk9PVA"
RCLONE_SOURCE="Display on TV"

RCLONE_BIN="/usr/bin/rclone"
HEIF_CONVERT_BIN="/usr/bin/heif-convert"
FEH_BIN="/usr/bin/feh"
IMAGEMAGICK_MAGICK_BIN="$(command -v magick || true)"
IMAGEMAGICK_CONVERT_BIN="$(command -v convert || true)"
EXIFTOOL_BIN="$(command -v exiftool || true)"
XDPYINFO_BIN="$(command -v xdpyinfo || true)"
PKILL_BIN="$(command -v pkill || true)"
PGREP_BIN="$(command -v pgrep || true)"
RSYNC_BIN="$(command -v rsync || true)"

SLIDESHOW_DELAY="10"

export DISPLAY=":0"
export XAUTHORITY="/home/gfd/.Xauthority"

LOG_FILE="/home/gfd/Pictures/PhotoFrame/sync.log"

###############################################################################
# Helpers
###############################################################################
timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(timestamp)] $*" | tee -a "$LOG_FILE"; }

ensure_dirs() { mkdir -p "$RAW_DIR" "$DISPLAY_DIR" 2>/dev/null; }
x_display_ready() { [ -n "$XDPYINFO_BIN" ] && $XDPYINFO_BIN -display "$DISPLAY" >/dev/null 2>&1; }

kill_feh_if_running() {
  if [ -n "$PGREP_BIN" ] && $PGREP_BIN -x feh >/dev/null 2>&1; then
    log "Stopping existing feh…"
    [ -n "$PKILL_BIN" ] && $PKILL_BIN -x feh || true
    sleep 0.5
  fi
}

start_feh() {
  if x_display_ready; then
    log "Starting feh slideshow…"
    nohup "$FEH_BIN" --quiet --fullscreen --auto-zoom \
      --slideshow-delay "$SLIDESHOW_DELAY" \
      "$DISPLAY_DIR" >> "$LOG_FILE" 2>&1 &
    disown || true
  else
    log "X display not ready; skipping feh restart this run."
  fi
}

###############################################################################
# HEIC → JPG with fallbacks
###############################################################################
convert_heic_to_jpg() {
  local src="$1"
  local dest_dir="$2"
  local base="$(basename "$src")"
  local stem="${base%.*}"
  local dest="$dest_dir/${stem}.jpg"
  local quarantine_dir="$(dirname "$src")/.quarantine"

  if [ -f "$dest" ]; then
    log "Already converted: $dest"
    return 0
  fi

  log "Converting: $src → $dest"

  if [ -x "$HEIF_CONVERT_BIN" ] && "$HEIF_CONVERT_BIN" "$src" "$dest" >/dev/null 2>&1; then
    log "heif-convert OK: $dest"
    return 0
  else
    log "heif-convert failed for: $src"
  fi

  if [ -n "$IMAGEMAGICK_MAGICK_BIN" ]; then
    if "$IMAGEMAGICK_MAGICK_BIN" "$src" -auto-orient -strip -quality 92 "$dest" >/dev/null 2>&1; then
      log "ImageMagick (magick) OK: $dest"
      return 0
    else
      log "ImageMagick (magick) failed for: $src"
    fi
  elif [ -n "$IMAGEMAGICK_CONVERT_BIN" ]; then
    if "$IMAGEMAGICK_CONVERT_BIN" "$src" -auto-orient -strip -quality 92 "$dest" >/dev/null 2>&1; then
      log "ImageMagick (convert) OK: $dest"
      return 0
    else
      log "ImageMagick (convert) failed for: $src"
    fi
  fi

  if [ -n "$EXIFTOOL_BIN" ]; then
    mkdir -p "$quarantine_dir"
    if "$EXIFTOOL_BIN" -b -PreviewImage "$src" > "$dest" 2>/dev/null && [ -s "$dest" ]; then
      log "Extracted PreviewImage via exiftool: $dest"
      return 0
    fi
  fi

  mkdir -p "$quarantine_dir"
  mv -f "$src" "$quarantine_dir/" && log "Quarantined problematic HEIC: $src → $quarantine_dir/"
  return 1
}

###############################################################################
# Cleanup
###############################################################################
cleanup_hdr_gainmaps() {
  find "$RAW_DIR" "$DISPLAY_DIR" -type f \
    -iname '*urn:com:apple:photo:2020:aux:hdrgainmap*' -print0 | xargs -0r rm -f
}

# Keep any Display image that:
#  - has a matching source in Raw with the SAME stem in (.jpg/.jpeg/.png any case), OR
#  - has a matching source HEIC with the SAME stem (meaning this JPG was converted).
cleanup_orphans_display_images() {
  log "Checking for orphaned display images..."
  local removed_count=0
  
  while IFS= read -r -d '' img; do
    fname="$(basename "$img")"
    stem="${fname%.*}"

    # Check if this exact file exists in RAW
    if [ -f "$RAW_DIR/$fname" ]; then
      continue
    fi
    
    # exists in RAW as non-HEIC with same stem?
    if ls "$RAW_DIR/$stem".{JPG,Jpg,jpg,JPEG,jpeg,PNG,png} >/dev/null 2>&1; then
      continue
    fi
    # exists in RAW as HEIC (source for our converted jpg)?
    if [ -f "$RAW_DIR/$stem.HEIC" ] || [ -f "$RAW_DIR/$stem.heic" ]; then
      continue
    fi

    log "Removing orphaned display file: $img"
    rm -f "$img"
    ((removed_count++))
  done < <(find "$DISPLAY_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)
  
  log "Removed $removed_count orphaned display files"
}

###############################################################################
# Main
###############################################################################
main() {
  {
    echo "=== Sync started at $(timestamp) ==="
    echo "DISPLAY=$DISPLAY"
    echo "XAUTHORITY=$XAUTHORITY"
  } >> "$LOG_FILE"

  ensure_dirs

  log "Running rclone sync from Shared Drive…"
  "$RCLONE_BIN" sync \
    --drive-team-drive="$RCLONE_TEAM_DRIVE_ID" \
    --drive-duplicates-mode first \
    --fast-list \
    "$RCLONE_REMOTE:$RCLONE_SOURCE" \
    "$RAW_DIR" >> "$LOG_FILE" 2>&1

  cleanup_hdr_gainmaps

  # Copy non-HEIC originals into Display (NO --delete here to avoid nuking converted JPGs)
  if [ -n "$RSYNC_BIN" ]; then
    log "Copying non-HEIC images to display directory via rsync…"
    local before_count=$(find "$DISPLAY_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | wc -l)
    
    "$RSYNC_BIN" -a --prune-empty-dirs \
      --include '*/' \
      --include '*.jpg' --include '*.JPG' \
      --include '*.jpeg' --include '*.JPEG' \
      --include '*.png' --include '*.PNG' \
      --exclude '*' \
      "$RAW_DIR"/ "$DISPLAY_DIR"/ >> "$LOG_FILE" 2>&1
    
    local after_count=$(find "$DISPLAY_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | wc -l)
    log "Display files before rsync: $before_count, after: $after_count"
  else
    log "rsync not found; skipping direct mirror of non-HEIC images."
  fi

  log "Converting HEIC images…"
  find "$RAW_DIR" -type f \( -iname '*.HEIC' -o -iname '*.heic' \) -print0 | while IFS= read -r -d '' heic; do
    convert_heic_to_jpg "$heic" "$DISPLAY_DIR"
  done

  # Now that everything is in place, remove any Display images with no source in Raw
  cleanup_orphans_display_images

  kill_feh_if_running
  start_feh

  log "Sync finished."
  echo "=== Sync finished at $(timestamp) ===" >> "$LOG_FILE"
}

main "$@"