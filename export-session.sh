#!/bin/bash
#
# Auggie Session Export Hook (SessionEnd)
# Automatically exports session files when a session ends

set -euo pipefail

# Configuration
EXPORT_DIR="${VOYAGER_SESSION_EXPORT_DIR:-/tmp/augment-sessions}"
CACHE_DIR="${AUGMENT_CACHE_DIR:-$HOME/.augment}"
LOG_FILE="${CACHE_DIR}/logs/session-export.log"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*" | tee -a "$LOG_FILE" >&2
}

# Read hook event data from stdin
EVENT_DATA=$(cat)

# Extract conversation_id (session ID) from hook event
CONVERSATION_ID=$(echo "$EVENT_DATA" | jq -r '.conversation_id // empty')

if [ -z "$CONVERSATION_ID" ]; then
  log "WARNING: No conversation_id found in SessionEnd event"
  exit 0
fi

log "INFO: SessionEnd hook triggered for session: $CONVERSATION_ID"

# Determine session file location
SESSION_FILE="$CACHE_DIR/sessions/$CONVERSATION_ID.json"

if [ ! -f "$SESSION_FILE" ]; then
  log "WARNING: Session file not found: $SESSION_FILE"
  exit 0
fi

# Create export directory if it doesn't exist
if ! mkdir -p "$EXPORT_DIR"; then
  log "ERROR: Failed to create export directory: $EXPORT_DIR"
  exit 1
fi

# Export session file
EXPORT_PATH="$EXPORT_DIR/$CONVERSATION_ID.json"

if cp "$SESSION_FILE" "$EXPORT_PATH"; then
  log "SUCCESS: Session exported to: $EXPORT_PATH"
  
  # Add metadata file with export timestamp
  cat > "$EXPORT_PATH.meta" <<METAEOF
{
  "session_id": "$CONVERSATION_ID",
  "exported_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "exported_from": "$(hostname)",
  "source_file": "$SESSION_FILE"
}
METAEOF
  
else
  log "ERROR: Failed to export session to: $EXPORT_PATH"
  exit 1
fi

exit 0
