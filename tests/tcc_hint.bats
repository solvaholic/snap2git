#!/usr/bin/env bats
# tests/tcc_hint.bats - hint when macOS TCC blocks git add

load test_helper

# Build a shim "git" that fails on `add -A` with TCC-style stderr,
# and passes everything else through to the real git. Returns the
# directory containing the shim on stdout.
make_failing_git_shim() {
  local real_git
  real_git="$(command -v git)"
  local shim_dir="$TEST_TMPDIR/shimbin"
  mkdir -p "$shim_dir"
  cat > "$shim_dir/git" <<EOF
#!/usr/bin/env bash
for a in "\$@"; do
  if [[ "\$a" == "add" ]]; then
    cat >&2 <<'ERR'
warning: could not open directory '.': Operation not permitted
error: open(".obsidian/app.json"): Operation not permitted
error: unable to index file '.obsidian/app.json'
fatal: updating files failed
ERR
    exit 1
  fi
done
exec "$real_git" "\$@"
EOF
  chmod +x "$shim_dir/git"
  echo "$shim_dir"
}

# Build a "uname" shim that reports the given OS for `-s`.
make_uname_shim() {
  local osname="$1" shim_dir="$2"
  cat > "$shim_dir/uname" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == "-s" ]]; then echo "$osname"; else exec /usr/bin/uname "\$@"; fi
EOF
  chmod +x "$shim_dir/uname"
}

@test "tcc hint: prints macOS FDA hint when git add reports Operation not permitted" {
  init_test_repo myrepo
  echo "hello" > "$TEST_WORKTREE/file.txt"

  shim_dir="$(make_failing_git_shim)"
  make_uname_shim Darwin "$shim_dir"

  PATH="$shim_dir:$PATH" run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -ne 0 ]
  [[ "$output" == *"Full Disk Access"* ]]
  [[ "$output" == *"Scheduled snapshots on macOS"* ]]
}

@test "tcc hint: not printed on non-Darwin systems" {
  init_test_repo myrepo
  echo "hello" > "$TEST_WORKTREE/file.txt"

  shim_dir="$(make_failing_git_shim)"
  make_uname_shim Linux "$shim_dir"

  PATH="$shim_dir:$PATH" run bash "$SNAP2GIT" snapshot myrepo
  [ "$status" -ne 0 ]
  [[ "$output" != *"Full Disk Access"* ]]
}
