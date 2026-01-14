# Auggie Session Export/Import

**Simple 5-minute setup to export and import Auggie sessions across machines.**

## What This Does

- **Automatically exports** Auggie sessions when they end
- **Manually import** sessions on a new machine  
- **Resume** sessions with `auggie --resume <session_id>`

Perfect for workflows with ephemeral servers, human-in-the-loop interactions, or session continuity across environments.

## Prerequisites

- Auggie CLI installed
- `jq` installed (for JSON processing)

```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq  # Ubuntu/Debian
sudo yum install jq      # RHEL/CentOS
```

---

## Setup Instructions

### Step 1: Copy the Export Hook Script

```bash
# Create the hooks directory
sudo mkdir -p /etc/augment/hooks

# Copy the export script
sudo cp export-session.sh /etc/augment/hooks/export-session.sh

# Make it executable
sudo chmod +x /etc/augment/hooks/export-session.sh

# Verify it was created
ls -la /etc/augment/hooks/export-session.sh
```

### Step 2: Configure the Hook

```bash
# Copy the settings file
sudo cp settings.json /etc/augment/settings.json

# Verify it's valid JSON
sudo cat /etc/augment/settings.json | jq .
```

### Step 3: Set the Export Location

```bash
# Add to your shell profile
echo '' >> ~/.bashrc
echo '# Auggie session export directory' >> ~/.bashrc
echo 'export SESSION_EXPORT_DIR="/tmp/augment-sessions"' >> ~/.bashrc

# Apply immediately
export SESSION_EXPORT_DIR="/tmp/augment-sessions"

# Create the directory
mkdir -p /tmp/augment-sessions

# Verify
echo $SESSION_EXPORT_DIR
```

**Note:** Change `/tmp/augment-sessions` to your preferred location (e.g., shared storage path).

**For zsh users:** Replace `~/.bashrc` with `~/.zshrc` in the commands above.

### Step 4: Install the Import Script

```bash
# Create bin directory if needed
mkdir -p ~/bin

# Copy the import script
cp import-session.sh ~/bin/import-session.sh

# Make it executable
chmod +x ~/bin/import-session.sh

# Add ~/bin to PATH if not already there
echo $PATH | grep -q "$HOME/bin" || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# Apply immediately
export PATH="$HOME/bin:$PATH"

# Verify
which import-session.sh
```

### Step 5: Restart Your Terminal

```bash
# Close and reopen your terminal, or run:
source ~/.bashrc  # or source ~/.zshrc for zsh
```

---

## Usage

### Export (Automatic)

Sessions are automatically exported when they end:

```bash
# Run auggie normally
auggie "Create a new feature"

# When the session ends, check the export:
ls -la /tmp/augment-sessions/
```

You'll see:
- `<session-id>.json` - The session file
- `<session-id>.json.meta` - Metadata (timestamp, hostname, etc.)

### Transfer

Copy the session file to the new machine:

```bash
# Option 1: SCP
scp /tmp/augment-sessions/<session-id>.json user@newhost:/tmp/

# Option 2: Shared storage
cp /tmp/augment-sessions/<session-id>.json /mnt/shared/

# Option 3: Cloud storage
aws s3 cp /tmp/augment-sessions/<session-id>.json s3://bucket/sessions/
```

### Import (Manual)

On the new machine:

```bash
# Import the session
import-session.sh /path/to/<session-id>.json
```

### Resume

```bash
# Resume the session
auggie --resume <session-id>

# Or use interactive picker
auggie --resume
```

---

## Complete Example Workflow

**Machine 1:**
```bash
# Start a session
auggie "Implement user authentication"

# Session ends (automatically exported to /tmp/augment-sessions/)

# Transfer to shared storage
cp /tmp/augment-sessions/abc-123-def.json /mnt/shared/
```

**Machine 2:**
```bash
# Import the session
import-session.sh /mnt/shared/abc-123-def.json

# Resume the session
auggie --resume abc-123-def
```

---

## Verification

Test that everything works:

```bash
# 1. Check export hook exists
ls -la /etc/augment/hooks/export-session.sh

# 2. Check settings are configured
sudo cat /etc/augment/settings.json | jq .

# 3. Check environment variable
echo $SESSION_EXPORT_DIR

# 4. Check import script
which import-session.sh

# 5. Run a test session
auggie "echo test"

# 6. Check export directory
ls -la /tmp/augment-sessions/
```

---

## Troubleshooting

### Sessions Not Exporting

**Check the export log:**
```bash
tail -20 ~/.augment/logs/session-export.log
```

**Verify hook is configured:**
```bash
sudo cat /etc/augment/settings.json
```

**Check export directory exists:**
```bash
ls -la $SESSION_EXPORT_DIR
```

### Import Fails

**Verify session file is valid JSON:**
```bash
jq . /path/to/session.json
```

**Check permissions:**
```bash
ls -la ~/.augment/sessions/
```

### Hook Error: "spawn ENOEXEC"

**Fix the shebang line:**
```bash
# Check first line
sudo head -1 /etc/augment/hooks/export-session.sh

# Should be: #!/bin/bash
# If not, recreate the file from export-session.sh
```

---

## Customization

### Change Export Location

Edit your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
# Change this line:
export SESSION_EXPORT_DIR="/your/custom/path"
```

### Add Cloud Upload

Edit `/etc/augment/hooks/export-session.sh` and add cloud upload commands after the export succeeds.

---

## Files Included

- `export-session.sh` - Hook script that exports sessions
- `import-session.sh` - Script to import sessions
- `settings.json` - Hook configuration for Auggie
- `README.md` - This file

---

## Important Notes

⚠️ **This is a workaround solution:**
- Relies on internal session file format
- May break in future Auggie versions
- Session files may contain sensitive information - secure appropriately

✅ **Best practices:**
- Use encrypted transfer methods (SCP, HTTPS)
- Set appropriate permissions on export directories
- Regularly clean up old exported sessions
- Test imports before relying on them in production

---

## Quick Reference

| Action | Command |
|--------|---------|
| Export (automatic) | Happens when session ends |
| Check exports | `ls -la $SESSION_EXPORT_DIR` |
| Import session | `import-session.sh /path/to/session.json` |
| Resume session | `auggie --resume <session-id>` |
| View export logs | `tail ~/.augment/logs/session-export.log` |
| List sessions | `ls ~/.augment/sessions/` |

---

**Setup complete! 🎉**

Test with: `auggie "echo hello"` and check `/tmp/augment-sessions/`

