#!/usr/bin/env bats
# tests/info.bats - repo statistics tests

load test_helper

@test "info: shows repo details" {
  init_test_repo
  echo "hello world" > "$TEST_WORKTREE/file1.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" info testrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Repository: testrepo"* ]]
  [[ "$output" == *"worktree:"* ]]
  [[ "$output" == *"git-dir:"* ]]
  [[ "$output" == *"size:"* ]]
  [[ "$output" == *"snapshots: 1"* ]]
  [[ "$output" == *"files:"* ]]
}

@test "info: shows extension breakdown" {
  init_test_repo
  echo "text" > "$TEST_WORKTREE/file1.txt"
  echo "data" > "$TEST_WORKTREE/file2.csv"
  echo "more text" > "$TEST_WORKTREE/file3.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" info testrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"By extension:"* ]]
  [[ "$output" == *".txt"* ]]
  [[ "$output" == *".csv"* ]]
}

@test "info: shows largest files" {
  init_test_repo
  echo "small" > "$TEST_WORKTREE/small.txt"
  # Create a slightly larger file
  dd if=/dev/zero of="$TEST_WORKTREE/bigger.bin" bs=1024 count=10 2>/dev/null
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" info testrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"Largest files:"* ]]
  [[ "$output" == *"bigger.bin"* ]]
}

@test "info: handles empty repo (no snapshots)" {
  init_test_repo
  run bash "$SNAP2GIT" info testrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"snapshots: 0"* ]]
}

@test "info: flags potential excludes" {
  init_test_repo
  mkdir -p "$TEST_WORKTREE/subdir/.cache"
  echo "cached" > "$TEST_WORKTREE/subdir/.cache/data"
  echo "real" > "$TEST_WORKTREE/notes.txt"

  # Need to snapshot with the cache dir (it won't be excluded by default
  # since .cache/ isn't in the default exclude list at the top level)
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" info testrepo
  [ "$status" -eq 0 ]
  # The .cache path should be flagged as a potential exclude
  [[ "$output" == *"Potential excludes"* ]] || [[ "$output" == *"notes.txt"* ]]
}

@test "info: no name fails" {
  run bash "$SNAP2GIT" info
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage:"* ]]
}

@test "info: snapshot count excludes init commit" {
  init_test_repo
  echo "v1" > "$TEST_WORKTREE/file.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  echo "v2" > "$TEST_WORKTREE/file.txt"
  run bash "$SNAP2GIT" snapshot testrepo

  run bash "$SNAP2GIT" info testrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"snapshots: 2"* ]]
}
