#!/usr/bin/env bats
# tests/checkout.bats - Tests for snap2git checkout command

load test_helper

@test "checkout: creates a temp worktree" {
  init_test_repo myrepo
  echo "hello" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"

  run bash "$SNAP2GIT" checkout myrepo HEAD
  [ "$status" -eq 0 ]
  [[ "$output" == *"Checked out"* ]]
  [[ "$output" == *".checkout-"* ]]

  # Verify the file exists in the checkout
  local checkout_dir
  checkout_dir=$(echo "$output" | grep -o "$SNAP2GIT_HOME/myrepo.checkout-[^ ]*")
  [ -f "$checkout_dir/file.txt" ]
  [ "$(cat "$checkout_dir/file.txt")" = "hello" ]
}

@test "checkout: idempotent - same ref reuses dir" {
  init_test_repo myrepo
  echo "hello" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"

  run bash "$SNAP2GIT" checkout myrepo HEAD
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" checkout myrepo HEAD
  [ "$status" -eq 0 ]
  [[ "$output" == *"already exists"* ]]
}

@test "checkout: --list shows active checkouts" {
  init_test_repo myrepo
  echo "hello" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"
  bash "$SNAP2GIT" checkout myrepo HEAD

  run bash "$SNAP2GIT" checkout myrepo --list
  [ "$status" -eq 0 ]
  [[ "$output" == *"checkout-"* ]]
}

@test "checkout: --list with no checkouts" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" checkout myrepo --list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No active checkouts"* ]]
}

@test "checkout: --cleanup removes checkouts" {
  init_test_repo myrepo
  echo "hello" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"
  bash "$SNAP2GIT" checkout myrepo HEAD

  run bash "$SNAP2GIT" checkout myrepo --cleanup
  [ "$status" -eq 0 ]
  [[ "$output" == *"Cleaned up"* ]]

  # Verify dir is gone
  local dirs
  dirs=$(ls -d "$SNAP2GIT_HOME"/myrepo.checkout-* 2>/dev/null || true)
  [ -z "$dirs" ]
}

@test "checkout: --cleanup with nothing to clean" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" checkout myrepo --cleanup
  [ "$status" -eq 0 ]
  [[ "$output" == *"No checkouts to clean"* ]]
}

@test "checkout: bad ref fails" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" checkout myrepo nonexistent-ref
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown ref"* ]]
}

@test "checkout: no name fails" {
  run bash "$SNAP2GIT" checkout
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

@test "checkout: no ref fails" {
  init_test_repo myrepo

  run bash "$SNAP2GIT" checkout myrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

@test "checkout: does not modify original worktree" {
  init_test_repo myrepo
  echo "original" > "$TEST_WORKTREE/file.txt"
  bash "$SNAP2GIT" snapshot myrepo -m "first"

  bash "$SNAP2GIT" checkout myrepo HEAD

  # Modify the checkout
  local checkout_dir
  checkout_dir=$(ls -d "$SNAP2GIT_HOME"/myrepo.checkout-* | head -1)
  echo "modified" > "$checkout_dir/file.txt"

  # Original worktree is untouched
  [ "$(cat "$TEST_WORKTREE/file.txt")" = "original" ]
}
