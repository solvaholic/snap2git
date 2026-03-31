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

## Commands

| Command | Description |
|---------|-------------|
| `init <name> <path>` | Set up a new snapshot repo |
| `snapshot <name>` | Take a snapshot (default command) |
| `status <name>` | Show changes since last snapshot |
| `log <name> [count]` | Show snapshot history |
| `verify <name>` | Check repo integrity with `git fsck` |
| `list` | List all configured repos |

## Snapshot Options

- `--dry-run` / `-n` - Preview changes without snapshotting
- `--stage-only` / `-s` - Stage changes but don't commit
- `--message` / `-m MSG` - Custom commit message

## Configuration

Config lives at `~/.config/snap2git/config` (INI-style):

```ini
[repo:my-notes]
worktree = ~/CloudDrive/Notes
branch = main
commit_template = Snapshot: %Y-%m-%d %H:%M:%S
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SNAP2GIT_HOME` | `~/.snap2git` | Where bare Git repos are stored |
| `SNAP2GIT_CONFIG` | `~/.config/snap2git/config` | Config file location |

## License

MIT
