---
name: release-day
description: Weekly release checklist for the Primecom repos (MSS monorepo and Flutter_Spider) - audit CHANGELOG.md against the commits since the last release, cross-check Jira (links in the changelog, tickets left unmarked), merge dev into the release branch on the user's go, watch the Gitea CI run and triage a failure, then do the post-release merge-back and version bump. Use when the user says "release day", "weekly release", "merge to main/master", "release X.Y.Z", "did we miss anything in the changelog", or asks to check Jira before a release.
---

# Release day

One pass per repo. Both repos release the same way: `dev` never builds, a merge
of `dev` into the release branch builds and publishes, CI bumps the build
number. The per-repo facts are in the table; everything else is shared.

| | MSS monorepo | Flutter_Spider |
| --- | --- | --- |
| Checkout | `~/src/monorepo` (WSL) | `/mnt/c/Users/User/primecom/Flutter_Spider` (`C:\Users\User\primecom\Flutter_Spider` on Windows) |
| Gitea repo | `mss/mss_monorepo` | `Primecom/Flutter_Spider` |
| Release branch | `main` | `master` |
| Version file | `VERSION` (`X.Y.Z` + `Build N`) | `pubspec.yaml` `version: X.Y.Z+N` |
| Changelog section | `## [vX.Y.Z] - date`, newest first | `## [vX.Y.Z DBvN] - date`, oldest first (new sections at the bottom after `---`) |
| CI jobs | `backend` (ubuntu container, runs as root) → `windows` → `publish` | `build-release` (windows runner) |
| Tag | `vX.Y.Z+N`, created by `mss ci-version` **before** the build | `vX.Y.Z+N`, created at publish on CI's bump commit |
| Bump | `Build 1` as committed ships as-is; a re-release bumps `Build` with a `[skip ci]` commit | CI always adds one: set `+0` on a version-name change, first release is `+1` |
| New version | `VERSION` + new changelog section, one commit | `pubspec.yaml` `+0` + new section, one commit |
| Typical run time | ~20 min (backend 14, windows 6) | check `docs/GITEA_ACTIONS.md` |

Jira site `primecom.atlassian.net`, project key `UZ` (the board is the whole
company; tickets are prefixed `FW:`, `SW:`, `TESTING:` in the summary). Jira
comments follow the `jira-done` skill of the repo and the Lithuanian rule in
the global CLAUDE.md (technical terms in English).

## 1. Clean start

- `git status` on `dev`. Stash WIP with a message (`git stash push -m "wip: ... before release"`);
  remember whether the stash touches `CHANGELOG.md`, because a changelog edit
  now will conflict on pop. Never carry WIP into the release merge.
- `git fetch origin`; `dev` must equal `origin/dev`.
- Read the version file and the last tag (`git tag --sort=-creatordate | head`).
  If a `vX.Y.Z+*` tag already exists for the committed version, this is a
  re-release of that version; CI will bump the build.

## 2. Changelog audit

- Commits in the release: `git log --oneline <release-branch>..dev`.
- The version's changelog section: `mss changelog` (monorepo) or `awk` the
  section out of `CHANGELOG.md`.
- Every commit that changes behaviour needs an entry. Chore/docs/CI-only commits
  do not. List what is missing instead of guessing entries; the user decides.
- Jira keys: `git log <release>..dev --format='%s%n%b' | grep -oE 'UZ-[0-9]+' | sort -u`
  versus the keys in the section. A key in a commit but not in the section is a
  missing link.
- Entries with no key at all: search Jira for a matching open ticket before
  calling them unticketed. JQL that worked:
  `project = UZ AND statusCategory != Done AND updated >= -45d ORDER BY updated DESC`
  (filter to the user's tickets and ones whose summary matches the entry). A
  bug ticket QA filed for a symptom the entry fixes is a missing link even when
  the commit never mentioned it.
- Link format in the entry: `[UZ-123](https://primecom.atlassian.net/browse/UZ-123) <ticket summary>: ...`.
- Also glance at the previous version's section for links that were missed last
  time; fixing them is cheap and the release body is what QA reads.

## 3. Jira audit

For every key referenced by the release (commits, changelog, matches found above):

- Status must be `READY TO TEST` with the version comment
  (`Sutaisyta, bus X.Y.Z versijoje`). Anything in `Backlog`, `To do`,
  `In Progress` or `In review` is forgotten: run the repo's `jira-done` skill.
- Write a real comment, not just the header, when the ticket needs it: cause,
  what QA should do to verify, which settings or developer-mode switch enable
  the feature, what is explicitly not covered. R&D tickets that ship behind a
  developer-mode switch say so ("R&D feature, klientams kol kas neįjungiama").
- QA comments on the ticket that describe a different symptom get one line
  saying it is a separate issue, so the ticket is not reopened for it.

## 4. Commit the audit fixes

Changelog links and Jira comments are the only edits here. Commit on `dev`
(subject only, `docs(changelog): link UZ-... to their entries`), show the
message, wait for go, push `dev`.

## 5. Release merge (explicit go required)

Never merge into `main`/`master` without the user saying so for this release.

```sh
git checkout <release> && git pull --ff-only
git merge --no-ff dev -m "Merge branch 'dev'"
git push origin <release>
git checkout dev
```

The merge commit message is the plain `Merge branch 'dev'`; that is what the
history has.

## 6. Watch CI

Gitea API with the token in `~/.config/mss/gitea-api.token` (the `mss` CLI's
API token; repos are private, unauthenticated calls 404):

```sh
T=$(tr -d '\n' < ~/.config/mss/gitea-api.token); API=https://gitea.primecom.work/api/v1/repos/<owner>/<repo>
curl -s -H "Authorization: token $T" "$API/actions/runs?limit=3" | jq -r '.workflow_runs[] | [.id,.status,.conclusion,.head_branch,.head_sha[0:7]] | @tsv'
curl -s -H "Authorization: token $T" "$API/actions/runs/<id>/jobs" | jq -r '.jobs[] | [.id,.name,.status,.conclusion] | @tsv'
curl -s -H "Authorization: token $T" "$API/actions/jobs/<job>/logs" -o job.log   # full log, ~2 MB
```

Use a Monitor that polls `/runs/<id>/jobs` every 45 s, prints each job state
change, and exits on the run's `completed` or any job `failure`. Do not poll by
hand. Keep logs and notes under `out/lab/<issue>/` or the scratchpad.

On failure:

- Pull the job log, find the step (`##[error]`, `tests failed`, `***Failed`),
  then the test's own output (`--output-on-failure` block).
- Reproduce locally before changing anything. Two things CI does differently:
  the monorepo backend container runs as **root** (`unshare -Ur ctest ...`
  reproduces uid 0 locally), and the box is slower, so timing races show up.
  A test that passes 5 times locally can still be the flaky one; loop it 30
  times.
- Fix on `dev` with a `fix(tests): ...` or `fix(ci): ...` commit, show the
  message, wait for go, then merge into the release branch again (step 5).
- Monorepo only: the tag was pushed before the build, so a failed run leaves
  `vX.Y.Z+N` on a commit that never released. Left alone, the retry bumps to
  `+N+1`. Ask the user; if they want the committed build number, delete the
  tag before the next push: `git push origin :refs/tags/vX.Y.Z+N`.
- A green run ends with a Gitea release at `/releases/tags/vX.Y.Z+N` carrying
  the archives, the changelog and `.sha256` files. Read it to confirm.

## 7. After the release

- Merge the release branch back into `dev` (`git checkout dev && git merge <release>`)
  so CI's bump commit does not conflict with the next version bump.
- Bump the version for the next cycle in one commit: monorepo `VERSION` to the
  next `X.Y.Z` with `Build 1` plus its new changelog section; Flutter_Spider
  `pubspec.yaml` to the next name with `+0` plus its section. Show the message,
  wait for go, push `dev`.
- Pop the stash from step 1 and resolve the changelog conflict if the audit
  touched it.
- Report in a few lines: version and tag released, tickets moved, anything
  left out (a fix parked for the next version, a flaky test, a CI quirk) and
  where the notes are.
