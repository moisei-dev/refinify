# Refinify Mac Deployment Context

## Session Summary (2026-07-17): Deployment overhaul

Fixed the root cause of "colleague had no ~/refinify folder" and "system prompt silently used generic default":

- `refinify-hammerspoon/refinify.lua` no longer resolves `.env-secrets`/`system-prompt-completion.md` relative to its own (symlinked) script directory. It now reads from `~/.config/refinify/refinify-secrets` and `~/.config/refinify/refinify-system-prompt.md`, resolved via `$HOME`.
- A `config.bootstrap()` function creates `~/.config/refinify/` and migrates existing files on first run, checking in order: legacy `~/refinify/` (old manual/portable installs, then deleted), legacy `~/.hammerspoon/.env-secrets` / `system-prompt-completion.md` (old scriptDir-relative scheme), then falls back to a bundled default prompt / empty template.
- `installers/mac/build-mac-app.sh`'s generated `setup-hammerspoon.sh` performs the same seeding/migration at install time (defense in depth with the lua-side bootstrap), and no longer opportunistically bundles whatever `.env-secrets*` files happen to sit in the build machine's repo root (that was a packaging bug, not real templating).
- The install script now waits for Hammerspoon to actually finish installing/launching (polling, not a blind `open -a Hammerspoon`), walks the user through granting Accessibility permissions, and forces a `hs.reload()` via AppleScript so the newly-symlinked `refinify.lua` takes effect without a manual restart.
- Root template files renamed `.env-secrets*.template` → `refinify-secrets*.template` (Windows still uses `.env-secrets` as its own destination filename, unaffected).
- Stale prebuilt artifacts (`installers/mac/Refinify.app/`, `Refinify-1.0.0-mac.zip`) were removed from git and gitignored — they had drifted from source and were a recurring source of confusion.
- Windows (`installers/windows/refinify.wxs`, AHK scripts, CI steps) intentionally untouched.

## Session Summary (2025-07-31)

### Issues Fixed

1. **hs.dialog.chooseFromList Error**
   - Error: `attempt to call a nil value (field 'chooseFromList')`
   - Cause: `hs.dialog.chooseFromList` doesn't exist in Hammerspoon
   - Fix: Replaced with `hs.chooser` API which is the correct way to create interactive choice lists
   - Location: `refinify-hammerspoon/refinify.lua:376`

2. **File Loading Error**
   - Error: `attempt to index a nil value (local 'file')` at line 33
   - Cause: No null check when `io.open` returns nil for missing files
   - Fix: Added fallback paths and null checks for both `loadSystemPrompt` and `loadConfigurationFromFile`
   - Now checks multiple locations (relative path, app bundle path) before failing gracefully

3. **System Prompt Not Being Used**
   - Issue: System prompt from `system-prompt-completion.md` wasn't affecting output
   - Cause: Mac implementation was using nested object structure for system message content
   - Fix: Changed from `content: [{type: "text", text: "..."}]` to simple `content: "..."`
   - Added debug logging to verify prompt loading

### Key Changes Made

1. **refinify-hammerspoon/refinify.lua**:
   - Replaced `hs.dialog.chooseFromList` with `hs.chooser` implementation
   - Added file existence checks and fallback paths
   - Simplified OpenAI API payload structure for system prompt
   - Added debug logging for troubleshooting

2. **Build Process**:
   - Successfully built Mac app using `build-mac-app.sh`
   - Created distributable `Refinify-1.0.0-mac.zip`
   - App includes all necessary resources and templates

### Git Configuration

- Fixed commit author from "Moisei Rabinovich" to "moisei"
- Set email to GitHub noreply address: `moisei-dev@users.noreply.github.com`
- Configuration command: `git config user.email "moisei-dev@users.noreply.github.com"`

### Testing Notes

- Configuration dialog now works properly with `hs.chooser`
- File loading handles missing files gracefully with fallback options
- System prompt is now properly loaded and used in API requests
- Debug messages can be viewed in Hammerspoon console

### Build Commands

```bash
# Build Mac app
pushd /home/moiseir/private/refinify-mac/installers/mac && bash build-mac-app.sh 1.0.0 && popd

# Create distributable zip
pushd /home/moiseir/private/refinify-mac/installers/mac && zip -r Refinify-1.0.0-mac.zip Refinify.app && popd
```

### Latest Release

- URL: https://github.com/moisei-dev/refinify/releases/tag/v1.1.0
- Note: This release doesn't include our fixes yet - would need v1.1.1

### Environment

- Working directory: `/home/moiseir/private/refinify-mac`
- Platform: Linux (WSL2)
- Git branch: main
- Project: https://github.com/moisei-dev/refinify