#!/usr/bin/env bash
# tests/group.bats - tests for snap2git group command

load test_helper

setup_two_repos() {
  mkdir -p "$TEST_TMPDIR/worktree1" "$TEST_TMPDIR/worktree2"
  run bash "$SNAP2GIT" init repo1 "$TEST_TMPDIR/worktree1"
  run bash "$SNAP2GIT" init repo2 "$TEST_TMPDIR/worktree2"
}

@test "group: add repos to a group" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1 repo2
  [ "$status" -eq 0 ]
  [[ "$output" == *"mygroup"* ]]
  [[ "$output" == *"repo1"* ]]
  [[ "$output" == *"repo2"* ]]
}

@test "group: --list shows groups" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1 repo2
  run bash "$SNAP2GIT" group --list
  [ "$status" -eq 0 ]
  [[ "$output" == *"mygroup"* ]]
}

@test "group: show group contents" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1 repo2
  run bash "$SNAP2GIT" group mygroup
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo1"* ]]
  [[ "$output" == *"repo2"* ]]
}

@test "group: remove repo from group" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1 repo2
  run bash "$SNAP2GIT" group mygroup remove repo1
  [ "$status" -eq 0 ]
  [[ "$output" != *"repo1"* ]]
  [[ "$output" == *"repo2"* ]]
}

@test "group: removing last repo deletes group" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1
  run bash "$SNAP2GIT" group mygroup remove repo1
  [ "$status" -eq 0 ]
  [[ "$output" == *"Removed group"* ]]

  run bash "$SNAP2GIT" group --list
  [[ "$output" != *"mygroup"* ]]
}

@test "group: snapshot operates on group" {
  setup_two_repos
  echo "file1" > "$TEST_TMPDIR/worktree1/a.txt"
  echo "file2" > "$TEST_TMPDIR/worktree2/b.txt"
  run bash "$SNAP2GIT" group mygroup add repo1 repo2

  run bash "$SNAP2GIT" snapshot mygroup
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo1"* ]]
  [[ "$output" == *"repo2"* ]]
}

@test "group: status operates on group" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1 repo2

  run bash "$SNAP2GIT" status mygroup
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo1"* ]]
  [[ "$output" == *"repo2"* ]]
}

@test "group: verify operates on group" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1 repo2

  run bash "$SNAP2GIT" verify mygroup
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo1"* ]]
  [[ "$output" == *"repo2"* ]]
}

@test "group: gc operates on group" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1 repo2

  run bash "$SNAP2GIT" gc mygroup
  [ "$status" -eq 0 ]
  [[ "$output" == *"repo1"* ]]
  [[ "$output" == *"repo2"* ]]
}

@test "group: name collision with repo fails" {
  setup_two_repos
  run bash "$SNAP2GIT" group repo1 add repo2
  [ "$status" -ne 0 ]
  [[ "$output" == *"conflicts"* ]]
}

@test "group: add nonexistent repo fails" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add nosuchrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "group: remove nonexistent repo from group fails" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1
  run bash "$SNAP2GIT" group mygroup remove repo2
  [ "$status" -ne 0 ]
  [[ "$output" == *"not in group"* ]]
}

@test "group: add without repos fails" {
  run bash "$SNAP2GIT" group mygroup add
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

@test "group: --list with no groups" {
  run bash "$SNAP2GIT" group --list
  [ "$status" -eq 0 ]
  [[ "$output" == *"No groups"* ]]
}

@test "group: add is idempotent (no duplicates)" {
  setup_two_repos
  run bash "$SNAP2GIT" group mygroup add repo1
  run bash "$SNAP2GIT" group mygroup add repo1
  [ "$status" -eq 0 ]
  # Should only have repo1 once
  local count
  count=$(bash "$SNAP2GIT" group mygroup 2>&1 | grep -o "repo1" | wc -l)
  [ "$count" -eq 1 ]
}
