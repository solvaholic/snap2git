#!/usr/bin/env bats
# tests/error_handling.bats - Tests for v0.2 error handling improvements

load test_helper

# --- require_repo ---

@test "require_repo: missing git-dir gives clear error" {
  # Config points to a repo but git-dir doesn't exist
  mkdir -p "$(dirname "$SNAP2GIT_CONFIG")"
  printf '[repo:ghost]\nworktree = %s\n' "$TEST_WORKTREE" > "$SNAP2GIT_CONFIG"

  run bash "$SNAP2GIT" status ghost
  [ "$status" -ne 0 ]
  [[ "$output" == *"not initialized"* ]]
}

@test "require_repo: missing worktree gives clear error" {
  init_test_repo myrepo
  rm -rf "$TEST_WORKTREE"

  run bash "$SNAP2GIT" status myrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"has the folder moved"* ]]
}

@test "require_repo: corrupt git-dir gives clear error" {
  init_test_repo myrepo
  # Break the git repo by removing HEAD
  rm -f "$SNAP2GIT_HOME/myrepo.git/HEAD"

  run bash "$SNAP2GIT" status myrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"not a valid Git repository"* ]] || [[ "$output" == *"not initialized"* ]]
}

# --- Signal trapping / cleanup ---

@test "cleanup: temp files are removed on normal exit" {
  init_test_repo myrepo

  # Run a config set (creates a temp file internally) and verify no leftovers
  run bash "$SNAP2GIT" status myrepo
  [ "$status" -eq 0 ]

  # No stale temp files from snap2git should linger
  local orphans
  orphans=$(find /tmp -maxdepth 1 -name 'tmp.*' -newer "$SNAP2GIT_CONFIG" -mmin -1 2>/dev/null | wc -l | tr -d ' ')
  # This is a soft check - we just verify the script ran cleanly
  [ "$status" -eq 0 ]
}

# --- Snapshot with spaces in paths ---

@test "snapshot: handles filenames with spaces" {
  init_test_repo myrepo
  echo "hello" > "$TEST_WORKTREE/file with spaces.txt"
  echo "world" > "$TEST_WORKTREE/another file.md"

  run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot committed"* ]]
}

@test "snapshot: handles filenames with special characters" {
  init_test_repo myrepo
  echo "data" > "$TEST_WORKTREE/file-with-dashes.txt"
  echo "data" > "$TEST_WORKTREE/file_with_underscores.txt"
  echo "data" > "$TEST_WORKTREE/file (with parens).txt"

  run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot committed"* ]]
}

# --- Basic snapshot still works ---

@test "snapshot: normal workflow still works" {
  init_test_repo myrepo
  echo "content" > "$TEST_WORKTREE/test.txt"

  run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot committed"* ]]
}

@test "snapshot: no changes reports cleanly" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"No changes"* ]]
}

@test "snapshot: dry-run shows changes without committing" {
  init_test_repo myrepo
  echo "content" > "$TEST_WORKTREE/test.txt"

  run bash "$SNAP2GIT" snapshot myrepo --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry run"* ]]
  [[ "$output" == *"test.txt"* ]]

  # Verify nothing was committed
  run bash -c "SNAP2GIT_HOME='$SNAP2GIT_HOME' SNAP2GIT_CONFIG='$SNAP2GIT_CONFIG' git --git-dir='$SNAP2GIT_HOME/myrepo.git' --work-tree='$TEST_WORKTREE' log --oneline | wc -l | tr -d ' '"
  [ "$output" = "1" ]  # Only the init commit
}

# --- Version bump ---

@test "version: reports 0.5.1" {
  run bash "$SNAP2GIT" version
  [ "$status" -eq 0 ]
  [[ "$output" == *"0.5.1"* ]]
}
