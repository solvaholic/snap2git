#!/usr/bin/env bats
# tests/exclude.bats - Tests for v0.2 exclude management

load test_helper

# --- Add pattern ---

@test "exclude: add a pattern" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" exclude myrepo "*.log"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Added exclude pattern"* ]]

  run bash "$SNAP2GIT" exclude myrepo --list
  [[ "$output" == *"*.log"* ]]
}

@test "exclude: add multiple patterns" {
  init_test_repo myrepo

  bash "$SNAP2GIT" exclude myrepo "*.log"
  bash "$SNAP2GIT" exclude myrepo "*.cache"

  run bash "$SNAP2GIT" exclude myrepo --list
  [[ "$output" == *"*.log"* ]]
  [[ "$output" == *"*.cache"* ]]
}

# --- List ---

@test "exclude: list shows default excludes" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" exclude myrepo --list
  [ "$status" -eq 0 ]
  [[ "$output" == *".DS_Store"* ]]
  [[ "$output" == *"*.icloud"* ]]
}

@test "exclude: list shows richer defaults" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" exclude myrepo --list
  [[ "$output" == *"OneDrive"* ]]
  [[ "$output" == *"__pycache__"* ]]
  [[ "$output" == *"RECYCLE"* ]]
}

# --- Reset ---

@test "exclude: reset restores defaults" {
  init_test_repo myrepo

  bash "$SNAP2GIT" exclude myrepo "*.custom"
  bash "$SNAP2GIT" exclude myrepo --reset

  run bash "$SNAP2GIT" exclude myrepo --list
  [[ "$output" != *"*.custom"* ]]
  [[ "$output" == *".DS_Store"* ]]
}

# --- Presets ---

@test "exclude: apply calibre preset" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" exclude myrepo --preset calibre
  [ "$status" -eq 0 ]
  [[ "$output" == *"Applied preset"* ]]

  run bash "$SNAP2GIT" exclude myrepo --list
  [[ "$output" == *"preset: calibre"* ]]
  [[ "$output" == *".cache/"* ]]
  [[ "$output" == *"full-text-search.db"* ]]
}

@test "exclude: preset is additive" {
  init_test_repo myrepo

  bash "$SNAP2GIT" exclude myrepo "*.custom"
  bash "$SNAP2GIT" exclude myrepo --preset calibre

  run bash "$SNAP2GIT" exclude myrepo --list
  [[ "$output" == *"*.custom"* ]]
  [[ "$output" == *"preset: calibre"* ]]
}

@test "exclude: unknown preset fails" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" exclude myrepo --preset nosuchpreset
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown preset"* ]]
}

@test "exclude: preset without name lists available" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" exclude myrepo --preset
  [ "$status" -eq 0 ]
  [[ "$output" == *"calibre"* ]]
}

# --- Edit (just test that it requires EDITOR) ---

@test "exclude: edit requires EDITOR" {
  init_test_repo myrepo
  unset EDITOR

  run bash -c "unset EDITOR; SNAP2GIT_HOME='$SNAP2GIT_HOME' SNAP2GIT_CONFIG='$SNAP2GIT_CONFIG' bash '$BATS_TEST_DIRNAME/../snap2git' exclude myrepo --edit"
  [ "$status" -ne 0 ]
  [[ "$output" == *"EDITOR"* ]]
}

# --- Excludes actually work ---

@test "exclude: excluded files are not snapshotted" {
  init_test_repo myrepo

  bash "$SNAP2GIT" exclude myrepo "*.secret"
  echo "public" > "$TEST_WORKTREE/file.txt"
  echo "private" > "$TEST_WORKTREE/data.secret"

  run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -eq 0 ]

  # The .secret file should not appear in git
  run bash -c "git --git-dir='$SNAP2GIT_HOME/myrepo.git' --work-tree='$TEST_WORKTREE' ls-files"
  [[ "$output" == *"file.txt"* ]]
  [[ "$output" != *"data.secret"* ]]
}

# --- Error cases ---

@test "exclude: no name fails" {
  run bash "$SNAP2GIT" exclude
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

@test "exclude: add without pattern fails" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" exclude myrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}
