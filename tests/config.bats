#!/usr/bin/env bats
# tests/config.bats - Tests for v0.2 config improvements

load test_helper

# --- Comment support ---

@test "config: comments with # are preserved through config_set" {
  init_test_repo myrepo

  # Add a comment manually
  sed -i '' '2i\
# This is a comment
' "$SNAP2GIT_CONFIG"

  # Update a key
  run bash "$SNAP2GIT" config myrepo commit_template "New: %Y-%m-%d"
  [ "$status" -eq 0 ]

  # Verify comment survived
  grep -q "^# This is a comment" "$SNAP2GIT_CONFIG"
}

@test "config: comments with ; are preserved through config_set" {
  init_test_repo myrepo

  sed -i '' '2i\
; semicolon comment
' "$SNAP2GIT_CONFIG"

  run bash "$SNAP2GIT" config myrepo commit_template "New: %Y-%m-%d"
  [ "$status" -eq 0 ]

  grep -q "^; semicolon comment" "$SNAP2GIT_CONFIG"
}

@test "config: comments are not returned as key values" {
  init_test_repo myrepo

  # Insert a commented-out worktree line before the real one
  local tmp
  tmp=$(mktemp)
  awk '/^worktree/ { print "# worktree = /wrong/path"; print; next } { print }' \
    "$SNAP2GIT_CONFIG" > "$tmp"
  mv "$tmp" "$SNAP2GIT_CONFIG"

  # Snapshot should use the real worktree, not the commented one
  echo "test" > "$TEST_WORKTREE/file.txt"
  run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot committed"* ]]
}

# --- config subcommand ---

@test "config: show displays repo config" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" config myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"[repo:myrepo]"* ]]
  [[ "$output" == *"worktree"* ]]
}

@test "config: set updates a value" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" config myrepo commit_template "Backup: %Y-%m-%d"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Set commit_template"* ]]

  run bash "$SNAP2GIT" config myrepo
  [[ "$output" == *"Backup: %Y-%m-%d"* ]]
}

@test "config: show nonexistent repo fails" {
  run bash "$SNAP2GIT" config nosuchrepo
  [ "$status" -ne 0 ]
}

@test "config: set without value fails" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" config myrepo somekey
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

# --- Config validation ---

@test "config: valid config passes validation" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" list
  [ "$status" -eq 0 ]
}

@test "config: missing worktree key fails validation" {
  mkdir -p "$(dirname "$SNAP2GIT_CONFIG")"
  printf '[repo:broken]\nbranch = main\n' > "$SNAP2GIT_CONFIG"

  run bash "$SNAP2GIT" list
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing required"* ]] || [[ "$output" == *"validation failed"* ]]
}

@test "config: --force overrides validation failure" {
  mkdir -p "$(dirname "$SNAP2GIT_CONFIG")"
  printf '[repo:broken]\nbranch = main\n' > "$SNAP2GIT_CONFIG"

  run bash "$SNAP2GIT" --force list
  [ "$status" -eq 0 ]
  [[ "$output" == *"validation failed"* ]] || [[ "$output" == *"warning"* ]]
}

@test "config: unknown section type warns" {
  mkdir -p "$(dirname "$SNAP2GIT_CONFIG")"
  printf '[global]\nfoo = bar\n[repo:ok]\nworktree = /tmp\n' > "$SNAP2GIT_CONFIG"

  run bash "$SNAP2GIT" list
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown section"* ]] || [[ "$output" == *"validation failed"* ]]
}

# --- Existing tests still pass ---

@test "config: init and snapshot still work" {
  init_test_repo myrepo
  echo "data" > "$TEST_WORKTREE/file.txt"

  run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot committed"* ]]
}
