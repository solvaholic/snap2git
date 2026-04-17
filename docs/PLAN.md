# snap2git - Plan

## v0 (shipped)

Single bash CLI with init, snapshot, status, log, verify, list.
Uses `--git-dir` / `--work-tree` to keep cloud drives clean.
Config at `~/.config/snap2git/config`, bare repos at `~/.snap2git/`.


## v0.2 - Polish and hardening (shipped)

### Multi-repo convenience
- Let commands operate on all repos when name is omitted
  (`snap2git snapshot` without a name snapshots everything)
- `snap2git snapshot --all` as explicit alternative

### Exclude management
- `snap2git exclude <name> <pattern>` - add patterns to info/exclude
- `snap2git exclude <name> --list` - show current excludes
- `snap2git exclude <name> --edit` - open in $EDITOR
- Ship a richer default exclude list (iCloud `.icloud` stubs, OneDrive
  placeholders, common IDE and editor temp files)
- `snap2git exclude <name> --preset <type>` - apply a curated set of
  exclude patterns for known collection types
- Built-in preset: `calibre` - excludes Calibre app state that bloats
  repos without adding library value (`.cache/`, `.config/`, `.calnotes/`,
  `full-text-search.db`)

### Config improvements
- `snap2git config <name>` - show config for a repo
- `snap2git config <name> <key> <value>` - update a setting
- Validate config on load (catch typos, missing keys)
- Support comments in config file

### Error handling and edge cases
- Graceful handling of locked files (cloud sync in progress)
- Better error messages when git-dir or worktree disappears
- Handle worktree paths with spaces in all code paths
- Trap signals for clean exit during long operations


## v0.3 - Diff and checkout (shipped)

### `snap2git diff <name> [ref1] [ref2]`
- Show what changed between two snapshots
- Default: diff last two snapshots
- `--stat` for summary, full diff for details
- `--name-only` for just file paths

### `snap2git checkout <name> <ref>`
- Check out a snapshot into a temp worktree for browsing
- Uses `git worktree add --detach` for safe, isolated access
- Temp worktrees live at `$SNAP2GIT_HOME/<name>.checkout-<short-ref>/`
- `snap2git checkout <name> --list` to see active checkouts
- `snap2git checkout <name> --cleanup` to remove temp worktrees

To recover files from an old snapshot, check it out and copy what you need.
This preserves the "never modify the worktree" principle - snap2git never
writes to your cloud folder, even for restores. The original plan had a
`restore` command; it was dropped to keep this guarantee.


## v0.4 - Automation and maintenance (shipped)

### Garbage collection
- `snap2git gc <name>` - run git gc with aggressive options
- `snap2git gc --all` for all repos
- Auto-gc after every 50 snapshots by default (configurable per-repo
  via `auto_gc_interval`, set to 0 to disable)
- Binary-aware `info/attributes` in the bare repo marks known compressed
  formats (epub, pdf, zip, cbz, jpg, png, mp3, mp4, etc.) with `-delta` -
  skips futile delta compression
- Attributes written at init time for new repos and during gc for existing

### Repo statistics
- `snap2git info <name>` - show repo size, snapshot count, date range,
  largest files, file count
- Break down size and file count by extension
- Flag potential excludes: files that look like app state or temp data

### Scheduled snapshots
- `snap2git schedule <name> <minutes>` - schedule periodic snapshots
- macOS: generates and loads a launchd plist
- Linux: installs a cron entry
- `snap2git schedule <name> --status` to check if active
- `snap2git schedule <name> --remove` to uninstall

### Deferred
- fswatch integration (`watch` command) was deferred to preserve the
  "no external dependencies beyond Git and Bash" principle. May revisit
  in a future version as an optional feature.


## v0.5 - Usability

### Smart init
- `snap2git init` detects files that a preset would exclude (e.g.
  `.obsidian/`, `metadata.db`) and auto-applies the relevant preset
- Prints what was applied and how to undo (`snap2git exclude <name> --edit`)
- Detection is root-only (no recursive scan) to avoid false positives
- `--no-excludes` flag skips all preset auto-detection
- `--exclude-preset <type>` flag to explicitly apply a preset at init time

### Shell completion
- `snap2git completion bash` prints a bash completion script to stdout
- `snap2git completion zsh` prints a native zsh completion script
- Completions cover commands, repo names, group names, flags, and preset names
- Setup: `eval "$(snap2git completion bash)"` in .bashrc (or zsh equivalent)

### Snapshot tagging and search
- `snap2git tag <name> <label>` - tag the latest snapshot
- `snap2git tag <name> --list` / `--delete <label>`
- `snap2git search <name> <pattern>` - find snapshots where content changed
  (wraps `git log -S` by default, `--regex` for `git log -G`)
- `snap2git search <name> --file <glob>` to restrict search to matching files

### Repo groups
- Named groups of repos, operated on together. Replaces the original
  "multiple worktrees per repo" concept with a simpler solution.
- Config: `[group:foo]` section with `repos = bar,baz`
- `snap2git group <name> add <repo>` / `remove` / `--list`
- Group names work in place of repo names for commands that support `--all`:
  snapshot, status, verify, gc

### Deferred
- Multiple worktrees per repo (tracking multiple source directories in a
  single Git history) was replaced by repo groups. The real use case was
  "act on these repos together", which groups solve without Git plumbing
  changes. True multi-worktree may be revisited if a unified-history use
  case emerges.


## Design notes

- No Git LFS for now - just warn on large files
- Local-only repos, no push/pull
- Scale target: 10,000 files, thousands of directories
- Keep it a single script as long as practical
