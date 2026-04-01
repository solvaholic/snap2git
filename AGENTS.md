# AGENTS.md - snap2git

## What is this project?

snap2git is a single-file Bash CLI that uses Git as invisible snapshot plumbing
for file collections (cloud drive folders, notes, etc.). It creates bare Git
repos in `~/.snap2git/` and points `--work-tree` at the user's actual folder -
no `.git` directory in the source, no copies, no syncing.

## Key files

- `snap2git` - The entire CLI. Single Bash script, ~420 lines. All commands
  live here: init, snapshot, status, log, verify, list.
- `README.md` - User-facing docs: quick start, commands, config, environment.
- `docs/PLAN.md` - Roadmap from v0 through v0.5. Defines what's shipped, what's
  next, and design constraints.
- `NOTES.md` - Working scratchpad for bugs, observations, and open questions.

## Architecture

- **No external dependencies** beyond Git and Bash. Intentionally a single
  script - the plan says "keep it a single script as long as practical."
- Config is INI-style at `~/.config/snap2git/config`. Parsed with awk.
- Bare repos live at `~/.snap2git/<name>.git`.
- `snap_git()` is the central helper - all Git operations go through it to
  set `--git-dir` and `--work-tree` correctly.
- Default excludes (OS junk, cloud sync markers, temp files) are written to
  `info/exclude` at init time.

## Design decisions to respect

- **Local-only** - no push/pull, no remotes.
- **Never modify the worktree** - snap2git reads from cloud folders but never
  writes to them. No checkouts against the live worktree.
- **`core.autocrlf = input`** - normalizes CRLF to LF in Git storage. Warnings
  about this are expected and documented in README.
- **Scale target** - 10,000 files, thousands of directories.
- **No Git LFS** - just warn on files >50MB.

## Current version

v0 is shipped. See `docs/PLAN.md` for v0.2+ roadmap items (multi-repo ops,
exclude management, diff/restore, fswatch, scheduled snapshots).

## Things to watch out for

- The default subcommand shorthand (`snap2git <name>` as alias for
  `snap2git snapshot <name>`) only works if the repo's git-dir exists.
  Unknown commands fail with an error, not a silent snapshot.
- Paths with spaces are used in real worktrees (iCloud folders). Test with them.
- `stat` flags differ between macOS (`-f%z`) and Linux (`-c%s`). The script
  handles both, but check if adding new file-size logic.
