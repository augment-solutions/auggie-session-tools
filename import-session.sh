#!/bin/bash
set -euo pipefail

CACHE_DIR="${AUGMENT_CACHE_DIR:-$HOME/.augment}"
SESSIONS_DIR="$CACHE_DIR/sessions"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() { echo -e "${RED}ERROR: $*${NC}" >&2; }
print_success() { echo -e "${GREEN}SUCCESS: $*${NC}"; }
print_warning() { echo -e "${YELLOW}WARNING: $*${NC}" >&2; }
print_info() { echo "INFO: $*"; }

if [ $# -ne 1 ]; then
  print_error "Usage: $0 <session_file.json>"
  exit 1
fi

SESSION_FILE="$1"

if [ ! -f "$SESSION_FILE" ]; then
  print_error "Session file not found: $SESSION_FILE"
  exit 1
fi

if ! jq empty "$SESSION_FILE" 2>/dev/null; then
  print_error "Invalid JSON in session file"
  exit 1
fi

SESSION_ID=$(jq -r '.sessionId // empty' "$SESSION_FILE")

if [ -z "$SESSION_ID" ]; then
  print_error "No sessionId found in session file"
  exit 1
fi

print_info "Importing session: $SESSION_ID"

mkdir -p "$SESSIONS_DIR"

DEST_FILE="$SESSIONS_DIR/$SESSION_ID.json"

if [ -f "$DEST_FILE" ]; then
  print_warning "Session already exists: $DEST_FILE"
  read -p "Overwrite? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Import cancelled"
    exit 0
  fi
fi

if cp "$SESSION_FILE" "$DEST_FILE"; then
  print_success "Session imported to: $DEST_FILE"
  print_info "Session ID: $SESSION_ID"
  print_info ""
  print_info "To resume this session, run:"
  print_info "  auggie --resume $SESSION_ID"
else
  print_error "Failed to import session"
  exit 1
fi

