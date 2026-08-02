# Releasing snap2git

This is the checklist for cutting a release. Follow it top to bottom; skipping steps is how we end up with a tag whose version doesn't match the script (the release job fails) or release notes that miss the point.

Releases are git tags on this repo (`vX.Y.Z`). There is no package registry - users install by downloading the `snap2git` script from the GitHub Release (see the README Install section). Pushing the tag is the only manual trigger; [`.github/workflows/release.yml`](../.github/workflows/release.yml) does the rest.

## What the release workflow does

On any pushed tag matching `v*`, `release.yml`:

1. Checks out the tagged commit.
2. **Verifies the tag matches the script.** It strips the leading `v` from the tag and compares against `SNAP2GIT_VERSION` in `snap2git`. If they differ, the job fails with an error - this is the guard that stops a mistagged release.
3. Creates a GitHub Release with auto-generated notes (categorized by the labels in [`.github/release.yml`](../.github/release.yml)) and attaches the `snap2git` script as a release asset.

So your job is to land a version bump on `main` and push a matching tag. Everything after the tag push is automated.

## Pick the SemVer bump

See [`docs/TRIAGE.md`](TRIAGE.md) for the full table. In short:

- **patch** (`v0.5.2`) - bug fixes, doc corrections, internal/CI. No new commands, flags, config keys, or presets.
- **minor** (`v0.6.0`) - new commands, flags, config keys, or presets; new user-facing behavior; no breaking changes.
- **major** (`v1.0.0`) - breaking changes to commands, config keys, or the on-disk repo/config layout.

## Pre-flight

- [ ] Working tree is clean on `main`, all PRs for this release merged, `git pull --ff-only` is a no-op.
- [ ] `README.md`, `docs/PLAN.md`, and help text (`snap2git --help`) reflect what's actually shipping. Any new command or flag is documented on all three surfaces.
- [ ] Local checks are green: `bash -n snap2git && shellcheck snap2git && bats tests/`.
- [ ] `grep -rn "X.Y.Z"` (the *old* version) to find every reference that pins it, so nothing is left behind.

## Bump the version

Two files carry the version and must move together:

1. `SNAP2GIT_VERSION` in [`snap2git`](../snap2git).
2. The matching assertion in [`tests/error_handling.bats`](../tests/error_handling.bats) - the `version: reports X.Y.Z` test.

If they drift, either `bats tests/` fails locally or the release job's tag/version check fails. Bump both in the same commit.

```sh
# Edit SNAP2GIT_VERSION="X.Y.Z" and the bats assertion, then confirm:
bash -n snap2git && shellcheck snap2git && bats tests/
```

## Land the bump on main

`main` is protected - direct pushes are blocked, so the bump lands via PR like any other change.

```sh
git switch -c release-vX.Y.Z
git add snap2git tests/error_handling.bats   # plus any release-worthy changes
git commit -m "Bump version to X.Y.Z"
git push -u origin release-vX.Y.Z
gh pr create --fill --base main
# ...merge the PR once CI is green...
```

## Tag and push

Tag the commit that's on `main` after the bump PR merges. The tag must point at a commit whose `SNAP2GIT_VERSION` equals the tag, or the release job fails.

```sh
git switch main && git pull --ff-only
# Sanity check: the version on main matches the tag you're about to push.
grep -m1 '^SNAP2GIT_VERSION=' snap2git      # expect X.Y.Z
git tag vX.Y.Z
git push origin vX.Y.Z
```

Pushing the tag triggers `release.yml`.

## Verify the release

- [ ] The **Release** workflow run for the tag is green (Actions tab). If the tag/version check failed, delete the tag (`git push origin :vX.Y.Z`), fix the mismatch on `main`, and re-tag.
- [ ] The GitHub Release exists for `vX.Y.Z` with the `snap2git` asset attached.
- [ ] Download the asset and confirm it runs: `curl -fsSL <asset-url> -o /tmp/snap2git && bash /tmp/snap2git --version` prints `snap2git X.Y.Z`.
- [ ] The README Install one-liner (`releases/latest/download/snap2git`) now resolves to this release.
- [ ] Edit the auto-generated notes to lead with user-facing highlights (what can users do now that they couldn't before?).

## Post-release

- [ ] Tick any `docs/PLAN.md` items that closed at this release; mark the next phase.

The issue-to-release mapping needs no extra bookkeeping: each closed issue's timeline shows the PR that closed it, and that PR appears in the release's auto-generated notes. To group fixed issues by shipped version, use a GitHub **Milestone per release** (see [`docs/TRIAGE.md`](TRIAGE.md)) rather than per-issue labels.

## Lessons learned

Seed entries from real releases here; future-you will thank you.
