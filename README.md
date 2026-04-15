# snap2git

Git-powered snapshots for file collections. Use your cloud drive folder as-is -
no `.git` folder in it, no copying, no syncing. Just invisible version control.

## Quick Start

```bash
# Make it executable
chmod +x snap2git

# Initialize a snapshot repo for your notes folder
./snap2git init my-notes ~/CloudDrive/Notes

# Take a snapshot
./snap2git snapshot my-notes

# Snapshot all repos at once
./snap2git snapshot

# See what changed since the last snapshot
./snap2git status my-notes

# View snapshot history
./snap2git log my-notes

# Verify repo integrity
./snap2git verify my-notes
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
| `verify [name]` | Check repo integrity with `git fsck` |
| `list` | List all configured repos |
| `config <name>` | Show config for a repo |
| `config <name> <key> <value>` | Update a config setting |
| `exclude <name> <pattern>` | Add an exclude pattern |
| `exclude <name> --list` | Show current exclude rules |
| `exclude <name> --edit` | Open excludes in `$EDITOR` |
| `exclude <name> --reset` | Reset excludes to defaults |
| `exclude <name> --preset <type>` | Apply a curated exclude preset |

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

## Snapshot Options

- `--all` / `-a` - Operate on all repos
- `--dry-run` / `-n` - Preview changes without snapshotting
- `--stage-only` / `-s` - Stage changes but don't commit
- `--message` / `-m MSG` - Custom commit message

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

## Configuration

Config lives at `~/.config/snap2git/config` (INI-style). Lines starting with
`#` or `;` are comments.

```ini
[repo:my-notes]
worktree = ~/CloudDrive/Notes
branch = main
commit_template = Snapshot: %Y-%m-%d %H:%M:%S
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
