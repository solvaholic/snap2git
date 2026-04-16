#!/usr/bin/env bats
# tests/schedule.bats - scheduled snapshot tests

load test_helper

@test "schedule: no name fails" {
  run bash "$SNAP2GIT" schedule
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage:"* ]]
}

@test "schedule: no interval fails" {
  init_test_repo
  run bash "$SNAP2GIT" schedule testrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"usage:"* ]]
}

@test "schedule: invalid interval fails" {
  init_test_repo
  run bash "$SNAP2GIT" schedule testrepo 0
  [ "$status" -ne 0 ]
  [[ "$output" == *"positive number"* ]]
}

@test "schedule: negative interval fails" {
  init_test_repo
  run bash "$SNAP2GIT" schedule testrepo -5
  [ "$status" -ne 0 ]
}

@test "schedule: non-numeric interval fails" {
  init_test_repo
  run bash "$SNAP2GIT" schedule testrepo abc
  [ "$status" -ne 0 ]
  [[ "$output" == *"positive number"* ]]
}

@test "schedule: macOS creates plist" {
  [[ "$(uname -s)" == "Darwin" ]] || skip "macOS only"
  init_test_repo

  run bash "$SNAP2GIT" schedule testrepo 60
  [ "$status" -eq 0 ]
  [[ "$output" == *"Scheduled"* ]]
  [[ "$output" == *"60 minutes"* ]]

  local plist_path="$HOME/Library/LaunchAgents/com.snap2git.testrepo.plist"
  [ -f "$plist_path" ]
  grep -q 'com.snap2git.testrepo' "$plist_path"
  grep -q '<integer>3600</integer>' "$plist_path"
  grep -q 'snapshot' "$plist_path"

  # Clean up
  launchctl unload "$plist_path" 2>/dev/null || true
  rm -f "$plist_path"
}

@test "schedule: macOS --status shows active schedule" {
  [[ "$(uname -s)" == "Darwin" ]] || skip "macOS only"
  init_test_repo

  run bash "$SNAP2GIT" schedule testrepo 30
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" schedule testrepo --status
  [ "$status" -eq 0 ]
  [[ "$output" == *"Schedule active"* ]]
  [[ "$output" == *"30 minutes"* ]]

  # Clean up
  local plist_path="$HOME/Library/LaunchAgents/com.snap2git.testrepo.plist"
  launchctl unload "$plist_path" 2>/dev/null || true
  rm -f "$plist_path"
}

@test "schedule: macOS --remove removes schedule" {
  [[ "$(uname -s)" == "Darwin" ]] || skip "macOS only"
  init_test_repo

  run bash "$SNAP2GIT" schedule testrepo 60
  [ "$status" -eq 0 ]

  run bash "$SNAP2GIT" schedule testrepo --remove
  [ "$status" -eq 0 ]
  [[ "$output" == *"Removed schedule"* ]]

  local plist_path="$HOME/Library/LaunchAgents/com.snap2git.testrepo.plist"
  [ ! -f "$plist_path" ]
}

@test "schedule: --status with no schedule" {
  init_test_repo
  run bash "$SNAP2GIT" schedule testrepo --status
  [ "$status" -eq 0 ]
  [[ "$output" == *"No schedule configured"* ]]
}

@test "schedule: --remove with no schedule fails" {
  init_test_repo
  run bash "$SNAP2GIT" schedule testrepo --remove
  [ "$status" -ne 0 ]
  [[ "$output" == *"no schedule found"* ]]
}
