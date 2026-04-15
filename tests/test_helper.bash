#!/usr/bin/env bash
# tests/test_helper.bash - shared setup/teardown for snap2git tests

SNAP2GIT="$BATS_TEST_DIRNAME/../snap2git"

setup() {
  TEST_TMPDIR="$(mktemp -d)"
  export SNAP2GIT_HOME="$TEST_TMPDIR/snap2git_home"
  export SNAP2GIT_CONFIG="$TEST_TMPDIR/snap2git_config"
  export TEST_WORKTREE="$TEST_TMPDIR/worktree"
  mkdir -p "$SNAP2GIT_HOME" "$TEST_WORKTREE"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Initialize a test repo with the given name.
init_test_repo() {
  local name="${1:-testrepo}"
  run bash "$SNAP2GIT" init "$name" "$TEST_WORKTREE"
}
