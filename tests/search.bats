#!/usr/bin/env bash
# tests/search.bats - tests for snap2git search command

load test_helper

setup_search_repo() {
  init_test_repo
  # First snapshot with a file
  echo "hello world" > "$TEST_WORKTREE/notes.txt"
  run bash "$SNAP2GIT" snapshot testrepo
  # Second snapshot that changes content
  echo "goodbye world" > "$TEST_WORKTREE/notes.txt"
  run bash "$SNAP2GIT" snapshot testrepo
}

@test "search: finds snapshots by string content" {
  setup_search_repo

  run bash "$SNAP2GIT" search testrepo "hello"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot"* ]]
}

@test "search: no results for unmatched pattern" {
  setup_search_repo

  run bash "$SNAP2GIT" search testrepo "zzzznothere"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "search: --regex uses git log -G" {
  setup_search_repo

  run bash "$SNAP2GIT" search testrepo --regex "hel+o"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot"* ]]
}

@test "search: --file restricts to matching files" {
  init_test_repo
  echo "secret" > "$TEST_WORKTREE/notes.txt"
  echo "secret" > "$TEST_WORKTREE/other.md"
  run bash "$SNAP2GIT" snapshot testrepo

  # Search restricted to *.md - should find the change in other.md
  run bash "$SNAP2GIT" search testrepo --file "*.md" "secret"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Snapshot"* ]]
}

@test "search: no name fails" {
  run bash "$SNAP2GIT" search
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}

@test "search: no pattern fails" {
  init_test_repo
  run bash "$SNAP2GIT" search testrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage"* ]]
}
