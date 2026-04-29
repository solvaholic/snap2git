# snap2git

Git-powered snapshots for file collections. Use your cloud drive folder as-is -
no `.git` folder in it, no copying, no syncing. Just invisible version control.

## Install

```bash
# Download the latest release
curl -fsSL https://github.com/solvaholic/snap2git/releases/latest/download/snap2git \
  -o /usr/local/bin/snap2git && chmod +x /usr/local/bin/snap2git
```

Or clone the repo and run it directly:

```bash
git clone https://github.com/solvaholic/snap2git.git
cd snap2git
chmod +x snap2git
./snap2git --version
```

**Requirements:** Bash (4.0+) and Git. Both are pre-installed on macOS and most
Linux distributions.

## Quick Start

```bash
# Initialize a snapshot repo for your notes folder
snap2git init my-notes ~/CloudDrive/Notes

# Take a snapshot
snap2git snapshot my-notes

# Snapshot all repos at once
snap2git snapshot

# See what changed since the last snapshot
snap2git status my-notes

# View snapshot history
snap2git log my-notes

# Verify repo integrity
snap2git verify my-notes
```

## How It Works

snap2git creates a bare Git repository in `~/.snap2git/` and tells Git to treat
your cloud drive folder as its work tree. Git reads files directly from the
source - no copies, no rsync, no duplication.

```
~/.snap2git/my-notes.git/    <-- Git history (invisible)
~/CloudDrive/Notes/           <-- Your files (untouched)
```

Cloud sync markers, OS junk, and temp files are automatically excluded.

## Line Endings (CRLF/LF)

snap2git sets `core.autocrlf = input` on init, which normalizes Windows-style
line endings (CRLF) to Unix-style (LF) when Git stores them. You may see
warnings like:

```
warning: in the working copy of 'file.csv', CRLF will be replaced by LF the next time Git touches it
```

This is expected and harmless. Your original files are never modified - snap2git
doesn't do checkouts. The normalization just keeps diffs clean when the same
files are edited on different platforms.

## Commands

| Command | Description |
|---------|-------------|
| `init <name> <path>` | Set up a new snapshot repo |
| `snapshot [name]` | Take a snapshot (all repos if name omitted) |
| `status [name]` | Show changes since last snapshot |
| `log <name> [count]` | Show snapshot history |
| `diff <name> [ref1] [ref2]` | Compare two snapshots |
| `checkout <name> <ref>` | Check out a snapshot to a temp dir |
| `checkout <name> --list` | Show active checkouts |
| `checkout <name> --cleanup` | Remove temp checkouts |
| `verify [name]` | Check repo integrity with `git fsck` |
| `list` | List all configured repos |
| `config <name>` | Show config for a repo |
| `config <name> <key> <value>` | Update a config setting |
| `exclude <name> <pattern>` | Add an exclude pattern |
| `exclude <name> --list` | Show current exclude rules |
| `exclude <name> --edit` | Open excludes in `$EDITOR` |
| `exclude <name> --reset` | Reset excludes to defaults |
| `exclude <name> --preset <type>` | Apply a curated exclude preset |
| `gc <name>` | Run garbage collection |
| `gc --all` | GC all repos |
| `info <name>` | Show repo statistics |
| `schedule <name> <min>` | Schedule periodic snapshots |
| `tag <name> <label>` | Tag the latest snapshot |
| `tag <name> --list` | List tags |
| `tag <name> --delete <label>` | Delete a tag |
| `search <name> <pattern>` | Find snapshots by content changes |
| `search <name> --regex <pat>` | Search with regex |
| `search <name> --file <glob>` | Restrict search to files matching glob |
| `group <name> add <repo>` | Add repos to a group |
| `group <name> remove <repo>` | Remove a repo from a group |
| `group --list` | List all groups |
| `completion bash` | Print bash completion script |
| `completion zsh` | Print zsh completion script |

### Scheduled snapshots on macOS

If your worktree lives in a TCC-protected location (iCloud Mobile
Documents, Desktop, Documents, Downloads, etc.), scheduled runs may
fail even when manual `snap2git snapshot` works. The log will show:

```
warning: could not open directory '.': Operation not permitted
error: open("..."): Operation not permitted
warning: No files could be staged for '<name>' (all may be locked).
```

**Why:** macOS Transparency, Consent, and Control (TCC) gates access to
those folders. Your Terminal app has been granted Full Disk Access
(FDA), so interactive runs work. `launchd`-spawned processes do not
inherit that grant - the interpreter (`/bin/bash`) runs without it.

snap2git only reads from the worktree (it never writes back), so this
is purely a read-permission issue.

**Options to resolve:**

- Grant Full Disk Access to the interpreter (e.g. `/bin/bash` or
  `/opt/homebrew/bin/bash`) under System Settings -> Privacy & Security
  -> Full Disk Access, then reload the launchd job. Simple but broad -
  any bash-based launchd job inherits FDA.
- Wrap snap2git in a dedicated launcher binary you control, and grant
  FDA only to that binary. More setup, narrower scope.
- Move the worktree out of the protected location, or stop scheduling
  that specific repo and snapshot it manually.

snap2git does not pick one for you; the trade-offs are yours.

## Multi-repo Operations

When you omit the repo name, `snapshot`, `status`, and `verify` operate on
all configured repos. The `--all` flag does the same thing explicitly:

```bash
snap2git snapshot          # snapshot everything
snap2git snapshot --all    # same thing
snap2git status            # check all repos for changes
snap2git verify --all      # verify all repos
```

If one repo fails (missing worktree, etc.), the others still run. A summary
at the end reports any failures.

### Repo Groups

Group repos together and operate on them as a unit:

```bash
# Create a group
snap2git group cloud add my-notes my-library

# Snapshot the group
snap2git snapshot cloud

# Status for the group
snap2git status cloud

# List groups
snap2git group --list
```

Groups work anywhere `--all` works: `snapshot`, `status`, `verify`, `gc`.

## Snapshot Options

- `--all` / `-a` - Operate on all repos
- `--dry-run` / `-n` - Preview changes without snapshotting
- `--stage-only` / `-s` - Stage changes but don't commit
- `--message` / `-m MSG` - Custom commit message

## Comparing Snapshots

The `diff` command shows what changed between snapshots:

```bash
# What changed in the last snapshot?
snap2git diff my-notes

# Summary of changes
snap2git diff my-notes --stat

# Just the file paths
snap2git diff my-notes --name-only

# Compare specific snapshots
snap2git diff my-notes HEAD~3 HEAD
```

Defaults to comparing the last two snapshots (`HEAD~1..HEAD`). You can use any
Git ref - commit hashes, `HEAD~N`, tags, etc.

## Checking Out Old Snapshots

The `checkout` command creates a read-only copy of a snapshot in a temp
directory. Your original files are never modified.

```bash
# Check out the previous snapshot
snap2git checkout my-notes HEAD~1

# Check out a specific commit
snap2git checkout my-notes abc1234

# See what's currently checked out
snap2git checkout my-notes --list

# Clean up all checkouts
snap2git checkout my-notes --cleanup
```

Checkouts live at `~/.snap2git/<name>.checkout-<ref>/`. Copy files out
manually - the intentional friction prevents accidental overwrites that could
sync back to your cloud folder.

## Exclude Rules

snap2git ships with default excludes for OS junk, cloud sync markers, temp
files, and IDE state. You can add your own:

```bash
# Add a pattern
snap2git exclude my-notes "*.log"

# See what's excluded
snap2git exclude my-notes --list

# Open in your editor
snap2git exclude my-notes --edit

# Reset to defaults (removes custom patterns)
snap2git exclude my-notes --reset
```

### Exclude Presets

Presets are curated sets of exclude patterns for specific collection types.
They're additive - they append to your existing excludes with a comment
header so you can find and remove them later.

During `init`, snap2git auto-detects files that match a preset and applies it
automatically. For example, if your worktree contains `metadata.db`, the
`calibre` preset is applied. You'll see a message like:

```
Applied exclude preset 'calibre' (detected matching files).
  Undo: snap2git exclude my-library --edit
```

To skip auto-detection: `snap2git init --no-excludes my-library ~/path`

To explicitly apply a preset at init:
`snap2git init --exclude-preset calibre my-library ~/path`

```bash
# Apply the calibre preset
snap2git exclude my-library --preset calibre

# List available presets
snap2git exclude my-library --preset
```

**Built-in presets:**

| Preset | Excludes |
|--------|----------|
| `calibre` | Calibre app state: `.cache/`, `.config/`, `.calnotes/`, `full-text-search.db` |
| `obsidian` | Obsidian vault metadata: `.obsidian/` |

## Tagging Snapshots

Tag snapshots with meaningful labels for easy reference:

```bash
snap2git tag my-notes before-reorg
snap2git tag my-notes --list
snap2git tag my-notes --delete before-reorg
```

Tags are lightweight Git tags on the latest commit. Use them with `diff`:
`snap2git diff my-notes before-reorg HEAD`

## Searching Snapshots

Find snapshots where specific content was added or removed:

```bash
# String search (git log -S)
snap2git search my-notes "TODO"

# Regex search (git log -G)
snap2git search my-notes --regex "fix(ed|ing)"

# Restrict to specific files
snap2git search my-notes --file "*.md" "draft"
```

## Shell Completion

Enable tab completion for commands, repo names, and flags:

```bash
# Bash - add to ~/.bashrc
eval "$(snap2git completion bash)"

# Zsh - add to ~/.zshrc
eval "$(snap2git completion zsh)"
```

## Configuration

Config lives at `~/.config/snap2git/config` (INI-style). Lines starting with
`#` or `;` are comments.

```ini
[repo:my-notes]
worktree = ~/CloudDrive/Notes
branch = main
commit_template = Snapshot: %Y-%m-%d %H:%M:%S

[group:cloud]
repos = my-notes,my-library
```

View or update config from the command line:

```bash
snap2git config my-notes                           # show config
snap2git config my-notes commit_template "Backup: %Y-%m-%d"  # set a value
```

Config is validated on startup. If there's a problem (missing keys, malformed
sections), snap2git will tell you what's wrong. Use `--force` to skip
validation if needed.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SNAP2GIT_HOME` | `~/.snap2git` | Where bare Git repos are stored |
| `SNAP2GIT_CONFIG` | `~/.config/snap2git/config` | Config file location |

## License

MIT
