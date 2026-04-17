#!/usr/bin/env bash
# tests/smart_init.bats - tests for smart init preset auto-detection

load test_helper

@test "smart init: detects calibre preset from metadata.db" {
  touch "$TEST_WORKTREE/metadata.db"
  run bash "$SNAP2GIT" init testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Applied exclude preset 'calibre'"* ]]
  [[ "$output" == *"detected matching files"* ]]

  # Verify preset was written to exclude file
  local exclude_file="$SNAP2GIT_HOME/testrepo.git/info/exclude"
  grep -q "preset: calibre" "$exclude_file"
  grep -q ".cache/" "$exclude_file"
}

@test "smart init: detects calibre preset from .caltrash" {
  mkdir -p "$TEST_WORKTREE/.caltrash"
  run bash "$SNAP2GIT" init testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Applied exclude preset 'calibre'"* ]]
}

@test "smart init: detects obsidian preset from .obsidian" {
  mkdir -p "$TEST_WORKTREE/.obsidian"
  run bash "$SNAP2GIT" init testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Applied exclude preset 'obsidian'"* ]]

  local exclude_file="$SNAP2GIT_HOME/testrepo.git/info/exclude"
  grep -q "preset: obsidian" "$exclude_file"
  grep -q ".obsidian/" "$exclude_file"
}

@test "smart init: detects multiple presets" {
  touch "$TEST_WORKTREE/metadata.db"
  mkdir -p "$TEST_WORKTREE/.obsidian"
  run bash "$SNAP2GIT" init testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Applied exclude preset 'calibre'"* ]]
  [[ "$output" == *"Applied exclude preset 'obsidian'"* ]]
}

@test "smart init: calibre preset not duplicated when both signatures match" {
  touch "$TEST_WORKTREE/metadata.db"
  mkdir -p "$TEST_WORKTREE/.caltrash"
  run bash "$SNAP2GIT" init testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]

  # Should only apply calibre once
  local exclude_file="$SNAP2GIT_HOME/testrepo.git/info/exclude"
  local count
  count=$(grep -c "preset: calibre" "$exclude_file")
  [ "$count" -eq 1 ]
}

@test "smart init: no presets applied when worktree is clean" {
  run bash "$SNAP2GIT" init testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Applied exclude preset"* ]]
}

@test "smart init: --no-excludes skips auto-detection" {
  touch "$TEST_WORKTREE/metadata.db"
  mkdir -p "$TEST_WORKTREE/.obsidian"
  run bash "$SNAP2GIT" init --no-excludes testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Applied exclude preset"* ]]
}

@test "smart init: --exclude-preset applies named preset" {
  run bash "$SNAP2GIT" init --exclude-preset calibre testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Applied exclude preset 'calibre'"* ]]
  [[ "$output" == *"--exclude-preset"* ]]

  local exclude_file="$SNAP2GIT_HOME/testrepo.git/info/exclude"
  grep -q "preset: calibre" "$exclude_file"
}

@test "smart init: --exclude-preset with unknown preset fails" {
  run bash "$SNAP2GIT" init --exclude-preset bogus testrepo "$TEST_WORKTREE"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown preset"* ]]
}

@test "smart init: --exclude-preset skips duplicate auto-detect" {
  touch "$TEST_WORKTREE/metadata.db"
  run bash "$SNAP2GIT" init --exclude-preset calibre testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]

  # Should only have one calibre preset section
  local exclude_file="$SNAP2GIT_HOME/testrepo.git/info/exclude"
  local count
  count=$(grep -c "preset: calibre" "$exclude_file")
  [ "$count" -eq 1 ]
}

@test "smart init: prints undo instructions for auto-detected presets" {
  mkdir -p "$TEST_WORKTREE/.obsidian"
  run bash "$SNAP2GIT" init testrepo "$TEST_WORKTREE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"snap2git exclude testrepo --edit"* ]]
}
