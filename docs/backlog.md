# Backlog

## v2.0 (current)
- [x] Rewrite lessons 1–12: LEARN/TASK split, no spoilers in TASK
- [x] Add Act II: lessons 13–24 (intermediate + capstone)
- [x] Game mechanics: XP, ranks, hint costs, reset, status/score/map
- [x] Hash-based flag checking (no plaintext leaks)
- [x] Validators for all 24 lessons (runtime skill checks)
- [x] Real challenge data for every lesson
- [x] install.sh idempotent + uninstall.sh
- [x] Dockerfile lab + CI (solvers + validators end-to-end)
- [x] README, curriculum, design doc, instructor guide

## Ideas
- [ ] Per-user leaderboard for shared VMs
- [ ] Lesson 25+: shell history tricks, xargs, tmux, git, LVM
- [ ] Randomized flags per install — **prerequisite:** validators must stop
      hardcoding flag values; compare artifacts against
      `/opt/flags/.hashes/lessonN.sha256` instead (see below)
- [ ] i18n of lesson text
- [ ] RPM/CentOS variant of install.sh

## Hardening discovered in iteration 4
- [ ] Make `validate_lesson` flag-free: it currently embeds all 24 flag
      values, so `grep FLAG{ /usr/local/bin/validate_lesson` hands a
      learner the answers. Checking artifact content against the public
      SHA-256 hashes would keep the same semantics without plaintext.
- [ ] Exclude the answer key from the shipped image: the Dockerfile does
      `COPY . /opt/LinuxFundamentalsCTF`, so `tests/solves/*.sh` (all 24
      flags) ships inside the documented Docker quickstart. CI should
      bind-mount the repo instead of relying on the in-image copy.
