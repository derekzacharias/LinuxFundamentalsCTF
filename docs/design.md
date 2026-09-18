# Design Document: Linux Fundamentals CTF v2

> Review findings, recommendations, and the iteration log for the rebuild.
> This document is the single source of truth for course design decisions.

## 1. Review of v1

### What worked
- A clear 12-lesson fundamentals arc (orientation → filesystem → files → perms → text → processes → packages → users/groups → PATH → scripting → search → networking).
- Solid core tooling: `ctf` CLI (with `lessons` kept as a back-compat wrapper) with menu/pager, `ctf submit`, `check_flag`, `hint`, `progress`, `validate_lesson`, MOTD-style `welcome.txt`.
- Per-user artifacts created at install time (hidden dir, wrapper script, group membership).
- systemd-backed dynamic challenges (lesson 6 logger, lesson 12 HTTP flag server).

### What held it back
| # | Finding | Impact |
|---|---------|--------|
| 1 | Lessons include the **exact solution commands** in the challenge text | No problem solving; turns the CTF into copy-paste |
| 2 | **No intermediate tier** — course stops at fundamentals | Advanced learners get nothing |
| 3 | **No scoring or game mechanics** — flat progress file, no XP, no consequences | Low engagement, no incentive to avoid hints |
| 4 | Hints exist for only 7 of 12 lessons, and `hint` expects a `HINT n:` prefix format inconsistently | Broken UX for the tool that matters most when stuck |
| 5 | `validate_lesson` checks exist at runtime but the repo ships **only lesson 1's validator**; backlog items were never completed | Instructors can't verify lessons 2–12 from the repo |
| 6 | Lesson 10 data is **empty placeholder files** (`touch app1..7.log`) — the flag value is unobtainable through the described challenge | Broken lesson |
| 7 | Flags are world-readable in `/opt/flags`, so most challenges can be trivially bypassed with `cat /opt/flags/*` | Weakens every lesson except 4 |
| 8 | No README, no curriculum map, no instructor guide | Onboarding friction |
| 9 | No automated tests or CI; no lab container definition | Regressions undetectable |
| 10 | No `uninstall`, install script is not idempotent in all paths | Poor hygiene for training VMs |

## 2. Design principles (v2)

1. **Command line only.** Every lesson is solvable from a plain shell — no GUI, no web app, no external services beyond localhost.
2. **Learn, then do.** Each lesson has four sections: OBJECTIVE → LEARN → TASK → HINTS/SUBMIT. The LEARN section teaches the skill; the TASK requires applying it without spoilers.
3. **Skills are verified, not just flags.** `ctf submit` runs `validate_lesson`, which checks that the learner actually performed the skill (file created, permission changed, cron installed, service started...).
4. **Progressive difficulty, cumulative skills.** Act I (Fundamentals, 1–12) teaches tools in isolation. Act II (Intermediate, 13–24) combines them; lesson 24 is a multi-stage capstone.
5. **Game mechanics:** XP (100/lesson), hint costs (hint 1 free, hint 2 = −10 XP, hint 3 = −20 XP), wrong submissions −5 XP, rank titles, `ctf status`/`ctf score` dashboards, `ctf reset`.
6. **Honest challenge design, honest threat model.** `check_flag` compares SHA-256 hashes, so protected flags in `/opt/flags` leak nothing through that path. But this is a LOCAL lab: lesson text, hint files, and validator scripts live on the same disk as the learner, so flag values are ultimately discoverable (grep the hints, read the scripts). The game accepts this — the real gate is the SKILL validator, which checks the artifacts each lesson must produce. Flag secrecy is best-effort; skill proof is enforced.
7. **Reproducible and tested.** A `Dockerfile` builds the lab; CI installs the course, runs a scripted "student solver" for every lesson, then asserts every `validate_lesson` passes. Solvers double as the instructor answer key.

## 3. Curriculum map

**Act I — Fundamentals (1–12)**
1. Orientation & first flag · 2. Paths & hidden files · 3. File operations · 4. Permissions & ownership · 5. Text, redirection, pipes · 6. Processes & logs · 7. Package management · 8. Users, groups, sudo · 9. PATH & environment · 10. Bash scripting I · 11. find & grep · 12. Networking basics

**Act II — Intermediate (13–24)**
13. Archives & compression · 14. Symbolic & hard links · 15. Shell expansion & quoting · 16. Job control & signals · 17. sed & awk · 18. Regex & grep mastery · 19. Users, permissions & ACLs deep dive · 20. systemd · 21. cron & scheduling · 22. SSH & remote access · 23. Networking tools · 24. Capstone: multi-stage breach

See `docs/curriculum.md` for per-lesson learning objectives.

## 4. Iteration log

| Iteration | Scope | Outcome |
|-----------|-------|---------|
| 1 | Rebuild: docs, 24 lessons, tooling, validators, data, install, tests, CI | Built; awaiting review |
| 2 | Independent review + live lab run: fixed 19 findings (hard-link kernel policy, systemd-in-container, validator fidelity, XP/reset exploits, hint tiering, data realism, CI robustness) | all 24 lessons PASS in lab container |
| 3 | Second independent review (fix verification + cheat audit + game-loop trace); fixed rank semantics, hint-penalty integrity, L10/L16/L23 pedagogy, wired `ctf brief` task cards, honest threat-model docs; live play-test exposed and fixed a critical bash `${:?}` parsing bug that broke `ctf submit`; game-loop regression added to CI | all 24 lessons + game loop PASS in fresh lab container |
| 4 | Independent audit of the installed-lab path (not just the container): fixed a P1 where `install.sh` never granted `adm`/`systemd-journal`, making lesson 20 unreadable on a real install (the Dockerfile had masked it); made `ctf reset <n>` XP-neutral; removed a flag value from lesson 1's hints (rule 1); fixed a gawk warning that `ctf hint` printed to stderr on every use; made lint able to fail (shellcheck) and cover the extensionless core scripts, and added `scripts/check-invariants.sh` (flags/hashes, hint format, leaks, solver+validator coverage, install/uninstall symmetry); made the lesson-22 solver idempotent and added a solver re-run check; added install preflight warnings; deleted v1 dead code; runtime-tested `uninstall.sh` for the first time | all 24 lessons + game loop + journal-access + reset-integrity + CLI-stderr + solver re-run checks PASS; 12/12 negative tests confirm each new check fails when it should |
