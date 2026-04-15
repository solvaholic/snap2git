#!/usr/bin/env bats
# tests/diff.bats - Tests for snap2git diff command

load test_helper

@test "diff: shows changes between last two snapshots" {
  init_test_repo myrepo
  echo "v1" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"
  echo "v2" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "second"

  run bash "$SNAP2GIT" diff myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"file.txt"* ]]
  [[ "$output" == *"v1"* ]] || [[ "$output" == *"v2"* ]]
}

@test "diff: --stat shows summary" {
  init_test_repo myrepo
  echo "v1" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"
  echo "v2" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "second"

  run bash "$SNAP2GIT" diff myrepo --stat
  [ "$status" -eq 0 ]
  [[ "$output" == *"file.txt"* ]]
  [[ "$output" == *"1 file changed"* ]] || [[ "$output" == *"changed"* ]]
}

@test "diff: --name-only shows just paths" {
  init_test_repo myrepo
  echo "v1" > "$TEST_WORKTREE/a.txt"
  echo "v1" > "$TEST_WORKTREE/b.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"
  echo "v2" > "$TEST_WORKTREE/a.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "second"

  run bash "$SNAP2GIT" diff myrepo --name-only
  [ "$status" -eq 0 ]
  [[ "$output" == *"a.txt"* ]]
  [[ "$output" != *"b.txt"* ]]
}

@test "diff: only one snapshot reports cleanly" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" diff myrepo
  [ "$status" -eq 0 ]
  [[ "$output" == *"nothing to diff"* ]]
}

@test "diff: explicit refs work" {
  init_test_repo myrepo
  echo "v1" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"
  echo "v2" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "second"
  echo "v3" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "third"

  run bash "$SNAP2GIT" diff myrepo HEAD~2 HEAD
  [ "$status" -eq 0 ]
  [[ "$output" == *"file.txt"* ]]
}

@test "diff: no name fails" {
  run bash "$SNAP2GIT" diff
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}
