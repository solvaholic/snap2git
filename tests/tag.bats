#!/usr/bin/env bash
# tests/tag.bats - tests for snap2git tag command

load test_helper

@test "tag: tags latest snapshot" {
  init_test_repo
  echo "hello" > "$TEST_WORKTREE/file.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" tag testrepo v1
  [ "$status" -eq 0 ]
  [[ "$output" == *"Tagged latest snapshot"* ]]
}

@test "tag: --list shows tags" {
  init_test_repo
  echo "hello" > "$TEST_WORKTREE/file.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  run bash "$SNAP2GIT" tag testrepo v1
  run bash "$SNAP2GIT" tag testrepo v2

  run bash "$SNAP2GIT" tag testrepo --list
  [ "$status" -eq 0 ]
  [[ "$output" == *"v1"* ]]
  [[ "$output" == *"v2"* ]]
}

@test "tag: --delete removes a tag" {
  init_test_repo
  echo "hello" > "$TEST_WORKTREE/file.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  run bash "$SNAP2GIT" tag testrepo v1

  run bash "$SNAP2GIT" tag testrepo --delete v1
  [ "$status" -eq 0 ]
  [[ "$output" == *"Deleted tag"* ]]

  run bash "$SNAP2GIT" tag testrepo --list
  [[ "$output" != *"v1"* ]]
}

@test "tag: no label fails" {
  init_test_repo
  run bash "$SNAP2GIT" tag testrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

@test "tag: no name fails" {
  run bash "$SNAP2GIT" tag
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

@test "tag: --delete without label fails" {
  init_test_repo
  run bash "$SNAP2GIT" tag testrepo --delete
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

@test "tag: duplicate tag fails" {
  init_test_repo
  echo "hello" > "$TEST_WORKTREE/file.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  run bash "$SNAP2GIT" tag testrepo v1
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" tag testrepo v1
  [ "$status" -ne 0 ]
}
