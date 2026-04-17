# Contributing to snap2git

## Development Setup

snap2git is a single Bash script with no build step. You just need:

- **Bash** (4.0+)
- **Git**
- **bats-core** for tests: `brew install bats-core` (macOS) or
  `sudo apt-get install bats` (Ubuntu)
- **ShellCheck** for linting: `brew install shellcheck` (macOS) or
  `sudo apt-get install shellcheck` (Ubuntu)

## Contribution Workflow

All changes to `main` go through pull requests. Direct pushes are blocked by
branch protection.

1. Create a branch: `git checkout -b my-feature`
2. Make your changes
3. Run checks locally: `bash -n snap2git && shellcheck snap2git && bats tests/`
4. Push and open a PR
5. CI must pass before merging

## Running Checks Locally

```bash
# Run everything CI runs, in order:
bash -n snap2git          # syntax check
shellcheck snap2git       # lint
bats tests/               # tests
```

```bash
# Run a specific test file
bats tests/error_handling.bats

# Run with verbose output (shows each test name)
bats --verbose-run tests/
```

Tests are fully isolated - each test creates its own temp directory with a
fresh `SNAP2GIT_HOME`, `SNAP2GIT_CONFIG`, and worktree. Nothing touches your
real config or repos.

## How Tests Work

Tests use [bats-core](https://bats-core.readthedocs.io/) (Bash Automated
Testing System). Each `.bats` file in `tests/` is a test file. Tests are
integration tests - they run real `snap2git` commands against real (temporary)
Git repos.

The shared helper `tests/test_helper.bash` provides:

- **`setup()`** - Creates a temp directory with `SNAP2GIT_HOME`,
  `SNAP2GIT_CONFIG`, and a test worktree. Runs before each test.
- **`teardown()`** - Removes the temp directory. Runs after each test.
- **`init_test_repo [name]`** - Initializes a test repo pointing at the
  temp worktree. Shortcut for the common setup pattern.

### Writing a Test

```bash
@test "snapshot: descriptive name of what you're testing" {
  # Set up a repo
  init_test_repo myrepo

  # Create some files in the worktree
  echo "content" > "$TEST_WORKTREE/file.txt"

  # Run snap2git and capture output + exit code
  run bash "$SNAP2GIT" snapshot myrepo

  # Assert exit code
  [ "$status" -eq 0 ]

  # Assert output contains expected text
  [[ "$output" == *"Snapshot committed"* ]]
}
```

### When to Write Tests

Write tests when you:

- **Add a new command or flag** - at minimum, test the happy path and one
  error case
- **Fix a bug** - write a test that would have caught it
- **Change behavior** - update or add tests that cover the new behavior
- **Touch path handling** - always test with spaces in filenames

### Test Organization

| File | Covers |
|------|--------|
| `tests/error_handling.bats` | Signal traps, require_repo, paths with spaces |
| `tests/config.bats` | Comment handling, validation, config subcommand |
| `tests/exclude.bats` | Exclude add/list/reset, presets |
| `tests/multi_repo.bats` | Multi-repo operations, continue-on-failure |
| `tests/diff.bats` | Diff between snapshots, --stat, --name-only |
| `tests/checkout.bats` | Checkout to temp dir, --list, --cleanup |
| `tests/gc.bats` | Garbage collection, auto-gc, binary attributes |
| `tests/info.bats` | Repo statistics, extension breakdown |
| `tests/schedule.bats` | Scheduled snapshots (launchd/cron) |
| `tests/smart_init.bats` | Auto-detect and apply exclude presets at init |
| `tests/tag.bats` | Snapshot tagging (tag/list/delete) |
| `tests/search.bats` | Content search (string/regex/file filter) |
| `tests/group.bats` | Repo groups (add/remove, batch operations) |

Add new test files for new feature areas. Load the helper at the top:

```bash
load test_helper
```

## Writing Exclude Presets

Presets are curated sets of exclude patterns for specific types of file
collections. They help users skip app state, caches, and other noise that
bloats repos without adding value.

### When to Write a Preset

A preset is worth adding when:

- A specific application stores state files alongside user content (like
  Calibre's `.cache/` and `full-text-search.db` next to `.epub` files)
- Multiple users are likely to encounter the same pattern
- The exclude patterns aren't obvious (users might not know what's safe to skip)

### How to Write a Preset

1. Add a function named `preset_<name>()` in the "Exclude presets" section of
   `snap2git`:

```bash
preset_myapp() {
  cat << 'PRESET'

# -- preset: myapp --
# Brief description of what this excludes and why
pattern1
pattern2/
*.pattern3
PRESET
}
```

2. Update `preset_list()` to include it:

```bash
echo "  myapp    - Brief description"
```

3. Add a test in `tests/exclude.bats`:

```bash
@test "exclude: apply myapp preset" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" exclude myrepo --preset myapp
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" exclude myrepo --list
  [[ "$output" == *"preset: myapp"* ]]
  [[ "$output" == *"pattern1"* ]]
}
```

4. Document it in the README preset table.

5. If the preset has detectable file signatures, add them to
   `preset_detect_signatures()` in `snap2git` so smart init can auto-apply it:

```bash
echo "myapp:distinctive-file-or-dir"
```

### Preset Conventions

- **Always start with a blank line** followed by `# -- preset: name --`
  so the preset is visually separated and users can find it to remove later
- **Add a comment** explaining what the patterns exclude and why
- **Use trailing `/` for directories** (e.g., `.cache/`)
- **Be conservative** - only exclude things that are clearly app state, not
  user content. When in doubt, leave it out.
- **Presets are additive** - they append to existing excludes, never replace

## Style and Conventions

- This is a single Bash script. Keep it that way as long as practical.
- Use `die()` for fatal errors, `warn()` for non-fatal, `info()` for normal output.
- All Git operations go through `snap_git()` - don't call `git` directly
  (except in `cmd_init` where the repo doesn't exist yet).
- Use `require_repo()` to validate repo state before operating.
- Use `if/then` instead of `[[ ]] && die` - the latter silently fails under
  `set -e` when it's the last statement in a function.
- Test with paths containing spaces - real worktrees (iCloud folders) have them.
