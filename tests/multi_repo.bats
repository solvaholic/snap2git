#!/usr/bin/env bats
# tests/multi_repo.bats - Tests for v0.2 multi-repo convenience

load test_helper

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export SNAP2GIT_HOME="$TEST_TMPDIR/snap2git_home"
  export SNAP2GIT_CONFIG="$TEST_TMPDIR/snap2git_config"
  export TEST_WORKTREE="$TEST_TMPDIR/worktree1"
  export TEST_WORKTREE2="$TEST_TMPDIR/worktree2"
  mkdir -p "$SNAP2GIT_HOME" "$TEST_WORKTREE" "$TEST_WORKTREE2"
}

init_two_repos() {
  bash "$SNAP2GIT" init repo1 "$TEST_WORKTREE"
  bash "$SNAP2GIT" init repo2 "$TEST_WORKTREE2"
}

# --- Snapshot all ---

@test "multi: snapshot with no name snapshots all repos" {
  init_two_repos
  echo "file1" > "$TEST_WORKTREE/a.txt"
  echo "file2" > "$TEST_WORKTREE2/b.txt"

  run bash "$SNAP2GIT" snapshot
  [ "$status" -eq 0 ]
  [[ "$output" == *"--- repo1 ---"* ]]
  [[ "$output" == *"--- repo2 ---"* ]]
  [[ "$output" == *"Snapshot committed"* ]]
}

@test "multi: snapshot --all snapshots all repos" {
  init_two_repos
  echo "file1" > "$TEST_WORKTREE/a.txt"
  echo "file2" > "$TEST_WORKTREE2/b.txt"

  run bash "$SNAP2GIT" snapshot --all
  [ "$status" -eq 0 ]
  [[ "$output" == *"--- repo1 ---"* ]]
  [[ "$output" == *"--- repo2 ---"* ]]
  [[ "$output" == *"All 2 repo(s) completed"* ]]
}

@test "multi: snapshot --all with no changes" {
  init_two_repos

  run bash "$SNAP2GIT" snapshot --all
  [ "$status" -eq 0 ]
  [[ "$output" == *"No changes"* ]]
}

@test "multi: snapshot with name still works" {
  init_two_repos
  echo "data" > "$TEST_WORKTREE/a.txt"

  run bash "$SNAP2GIT" snapshot repo1
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot committed"* ]]
  # Should NOT mention repo2
  [[ "$output" != *"repo2"* ]]
}

# --- Status all ---

@test "multi: status with no name shows all repos" {
  init_two_repos
  echo "changed" > "$TEST_WORKTREE/a.txt"

  run bash "$SNAP2GIT" status
  [ "$status" -eq 0 ]
  [[ "$output" == *"--- repo1 ---"* ]]
  [[ "$output" == *"--- repo2 ---"* ]]
  [[ "$output" == *"a.txt"* ]]
}

@test "multi: status --all shows all repos" {
  init_two_repos

  run bash "$SNAP2GIT" status --all
  [ "$status" -eq 0 ]
  [[ "$output" == *"--- repo1 ---"* ]]
  [[ "$output" == *"--- repo2 ---"* ]]
}

# --- Verify all ---

@test "multi: verify with no name verifies all repos" {
  init_two_repos

  run bash "$SNAP2GIT" verify
  [ "$status" -eq 0 ]
  [[ "$output" == *"--- repo1 ---"* ]]
  [[ "$output" == *"--- repo2 ---"* ]]
  [[ "$output" == *"Integrity check passed"* ]]
}

@test "multi: verify --all verifies all repos" {
  init_two_repos

  run bash "$SNAP2GIT" verify --all
  [ "$status" -eq 0 ]
  [[ "$output" == *"All 2 repo(s) completed"* ]]
}

# --- Error handling: continue on failure ---

@test "multi: snapshot continues after one repo fails" {
  init_two_repos
  echo "data" > "$TEST_WORKTREE/a.txt"
  echo "data" > "$TEST_WORKTREE2/b.txt"

  # Break repo1's worktree
  rm -rf "$TEST_WORKTREE"

  run bash "$SNAP2GIT" snapshot --all
  [ "$status" -ne 0 ]
  # repo1 should fail
  [[ "$output" == *"failed: repo1"* ]] || [[ "$output" == *"not found"* ]]
  # repo2 should succeed
  [[ "$output" == *"--- repo2 ---"* ]]
  [[ "$output" == *"Snapshot committed"* ]]
  [[ "$output" == *"1 of 2"* ]]
}

@test "multi: status continues after one repo fails" {
  init_two_repos

  # Break repo1's git-dir
  rm -rf "$SNAP2GIT_HOME/repo1.git"

  run bash "$SNAP2GIT" status --all
  [ "$status" -ne 0 ]
  [[ "$output" == *"--- repo2 ---"* ]]
  [[ "$output" == *"1 of 2"* ]]
}

# --- Edge: no repos configured ---

@test "multi: snapshot all with no repos gives error" {
  run bash "$SNAP2GIT" snapshot --all
  [ "$status" -ne 0 ]
  [[ "$output" == *"no repos configured"* ]]
}

# --- Snapshot --all with flags ---

@test "multi: snapshot --all --dry-run" {
  init_two_repos
  echo "data" > "$TEST_WORKTREE/a.txt"
  echo "data" > "$TEST_WORKTREE2/b.txt"

  run bash "$SNAP2GIT" snapshot --all --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry run"* ]]
  [[ "$output" == *"--- repo1 ---"* ]]
  [[ "$output" == *"--- repo2 ---"* ]]
}
