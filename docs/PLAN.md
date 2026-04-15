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


## v0.3 - Diff and restore

### `snap2git diff <name> [ref1] [ref2]`
- Show what changed between two snapshots
- Default: diff last two snapshots
- `--stat` for summary, full diff for details
- `--name-only` for just file paths

### `snap2git checkout <name> <ref> [path]`
- Check out a snapshot (or specific files) into a temp worktree
- Uses `git worktree add` for safe, isolated browsing
- `snap2git checkout <name> --list` to see active checkouts
- `snap2git checkout <name> --cleanup` to remove temp worktrees

### `snap2git restore <name> <ref> [path]`
- Restore specific files from a snapshot back to the live worktree
- Confirmation prompt before overwriting (unless --force)
- `--dry-run` to preview what would be restored


## v0.4 - Automation and maintenance

### fswatch integration
- `snap2git watch <name>` - start watching with fswatch
- Debounce with configurable latency (default 30s)
- Coalesce rapid changes into single snapshots
- Log to file, daemonize option

### Scheduled snapshots
- Generate launchd plist for macOS (`snap2git schedule <name> <interval>`)
- Cron fallback for Linux

### Garbage collection
- `snap2git gc <name>` - run git gc with aggressive options
- Configurable auto-gc (e.g. every N snapshots or every N days)
- `snap2git gc --all` for all repos
- Set binary-aware `.gitattributes` in the bare repo during gc (or at
  init time) to mark known compressed formats (epub, pdf, zip, cbz, jpg,
  png, mp3, mp4) with `-delta` - skips futile delta compression and saves
  significant CPU on binary-heavy repos

### Repo statistics
- `snap2git info <name>` - show repo size, snapshot count, date range,
  largest files, file count over time
- Break down size and file count by extension so users can see what's
  eating space (e.g. "48.5 GB across 2,066 .epub files")
- Flag potential excludes: files that look like app state or temp data
  rather than user content


## v0.5 - Usability

### Shell completion
- bash completion for commands, repo names, and flags
- zsh completion

### Snapshot tagging and search
- `snap2git tag <name> <label>` - tag the latest snapshot
- `snap2git search <name> <pattern>` - find snapshots where a file
  matched a pattern (wraps `git log -S` / `git log -G`)

### Multiple worktrees per repo
- Allow a single named repo to track multiple source directories
  (e.g. iCloud Notes + OneDrive Documents in one history)


## Design notes

- No Git LFS for now - just warn on large files
- Local-only repos, no push/pull
- Scale target: 10,000 files, thousands of directories
- Keep it a single script as long as practical
