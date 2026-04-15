# AGENTS.md - snap2git

## What is this project?

snap2git is a single-file Bash CLI that uses Git as invisible snapshot plumbing
for file collections (cloud drive folders, notes, etc.). It creates bare Git
repos in `~/.snap2git/` and points `--work-tree` at the user's actual folder -
no `.git` directory in the source, no copies, no syncing.

## Key files

- `snap2git` - The entire CLI. Single Bash script, ~1000 lines. Commands:
  init, snapshot, status, log, diff, checkout, verify, list, config, exclude.
- `README.md` - User-facing docs: quick start, commands, config, excludes,
  presets, multi-repo operations.
- `CONTRIBUTING.md` - Developer guide: running tests, writing presets, writing
  tests.
- `docs/PLAN.md` - Roadmap from v0 through v0.5. Defines what's shipped, what's
  next, and design constraints.
- `tests/` - bats-core integration tests. Each test creates a real snapshot repo
  in a temp directory and runs commands against it.

## Architecture

- **No external dependencies** beyond Git and Bash. Intentionally a single
  script - the plan says "keep it a single script as long as practical."
- Config is INI-style at `~/.config/snap2git/config`. Parsed with awk.
  Lines starting with `#` or `;` are comments. Validated on startup.
- Bare repos live at `~/.snap2git/<name>.git`.
- `snap_git()` is the central helper - all Git operations go through it to
  set `--git-dir` and `--work-tree` correctly.
- `require_repo()` validates that a repo's git-dir and worktree exist before
  operating. Uses `git rev-parse` to check git-dir validity, not just `-d`.
- Default excludes (OS junk, cloud sync markers, temp files, IDE state) are
  written to `info/exclude` at init time. Users extend them with `exclude`.
- Exclude presets are functions named `preset_<name>()` that emit patterns.
  Adding a preset means adding one function.
- Multi-repo commands (`snapshot`, `status`, `verify`) use `run_for_all()`
  which runs each repo in a subshell so `die()` in one doesn't kill the batch.
- Signal trapping cleans up temp files on EXIT/INT/TERM. Temp files are
  tracked in the `SNAP2GIT_TMPFILES` array.

## Design decisions to respect

- **Local-only** - no push/pull, no remotes.
- **Never modify the worktree** - snap2git reads from cloud folders but never
  writes to them. Checkouts go to a separate temp directory, never the source.
  The `checkout` command uses `git worktree add --detach` to create an isolated
  copy at `~/.snap2git/<name>.checkout-<ref>/`.
- **`core.autocrlf = input`** - normalizes CRLF to LF in Git storage. Warnings
  about this are expected and documented in README.
- **Scale target** - 10,000 files, thousands of directories.
- **No Git LFS** - just warn on files >50MB.

## Current version

v0.3 is shipped. See `docs/PLAN.md` for v0.4+ roadmap items (fswatch,
scheduled snapshots, garbage collection).

## Testing

Tests use bats-core. Install with `brew install bats-core`, run with
`bats tests/`. Each test gets its own temp directory for `SNAP2GIT_HOME`,
`SNAP2GIT_CONFIG`, and a fake worktree - tests are fully isolated.

See `CONTRIBUTING.md` for details on writing tests and presets.

## Things to watch out for

- The default subcommand shorthand (`snap2git <name>` as alias for
  `snap2git snapshot <name>`) only works if the repo's git-dir exists.
  Unknown commands fail with an error, not a silent snapshot.
- Paths with spaces are used in real worktrees (iCloud folders). Test with them.
- `stat` flags differ between macOS (`-f%z`) and Linux (`-c%s`). The script
  handles both, but check if adding new file-size logic.
- In `set -e` bash scripts, `[[ cond ]] && die` at the end of a function
  returns 1 when the condition is false. Always use `if/then` instead.
- Multi-repo commands run each repo in a subshell. Side effects (like setting
  variables) won't propagate back to the caller.
