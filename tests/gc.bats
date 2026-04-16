#!/usr/bin/env bats
# tests/gc.bats - garbage collection tests

load test_helper

@test "gc: basic gc on a repo with snapshots" {
  init_test_repo
  echo "file1" > "$TEST_WORKTREE/file1.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" gc testrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"GC complete"* ]]
}

@test "gc: writes binary attributes file" {
  init_test_repo
  run bash "$SNAP2GIT" gc testrepo
  [ "$status" -eq 0 ]

  local attrs_file="$SNAP2GIT_HOME/testrepo.git/info/attributes"
  [ -f "$attrs_file" ]
  grep -q '*.epub -delta' "$attrs_file"
  grep -q '*.pdf -delta' "$attrs_file"
  grep -q '*.mp3 -delta' "$attrs_file"
  grep -q '*.zip -delta' "$attrs_file"
}

@test "gc: init writes binary attributes" {
  init_test_repo
  local attrs_file="$SNAP2GIT_HOME/testrepo.git/info/attributes"
  [ -f "$attrs_file" ]
  grep -q '*.epub -delta' "$attrs_file"
}

@test "gc: --all runs gc on all repos" {
  init_test_repo "repo1"
  local wt2="$TEST_TMPDIR/worktree2"
  mkdir -p "$wt2"
  run bash "$SNAP2GIT" init repo2 "$wt2"
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" gc --all
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo1"* ]]
  [[ "$output" == *"repo2"* ]]
  [[ "$output" == *"All 2 repo(s) completed successfully"* ]]
}

@test "gc: auto-gc counter increments on snapshot" {
  init_test_repo
  echo "file1" > "$TEST_WORKTREE/file1.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  local count_file="$SNAP2GIT_HOME/testrepo.git/snap2git-snapshot-count"
  [ -f "$count_file" ]
  local count
  count=$(cat "$count_file")
  [ "$count" -eq 1 ]
}

@test "gc: auto-gc triggers at threshold" {
  init_test_repo
  # Set auto-gc interval to 2 for fast testing
  run bash "$SNAP2GIT" config testrepo auto_gc_interval 2
  [ "$status" -eq 0 ]

  echo "file1" > "$TEST_WORKTREE/file1.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  local count_file="$SNAP2GIT_HOME/testrepo.git/snap2git-snapshot-count"
  local count
  count=$(cat "$count_file")
  [ "$count" -eq 1 ]

  echo "file2" > "$TEST_WORKTREE/file2.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Auto-gc triggered"* ]]

  # Counter should reset to 0 after gc
  count=$(cat "$count_file")
  [ "$count" -eq 0 ]
}

@test "gc: auto-gc disabled with interval 0" {
  init_test_repo
  run bash "$SNAP2GIT" config testrepo auto_gc_interval 0
  [ "$status" -eq 0 ]

  echo "file1" > "$TEST_WORKTREE/file1.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  local count_file="$SNAP2GIT_HOME/testrepo.git/snap2git-snapshot-count"
  # Counter file should not exist when auto-gc is disabled
  [ ! -f "$count_file" ]
}

@test "gc: no repo name runs gc on all" {
  init_test_repo
  run bash "$SNAP2GIT" gc
  [ "$status" -eq 0 ]
  [[ "$output" == *"GC complete"* ]]
}
