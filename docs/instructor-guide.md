# Instructor Guide

## Lab requirements

`install.sh` installs the course, not its dependencies. A lab machine needs:

- **systemd** — lessons 6, 12, 20 and 23 run services. `install.sh` warns
  when systemd is not running; those lessons cannot be completed without it.
- **sudo for every learner** — lessons 4, 20, 22, 23 and 24 use it.
  `install.sh` warns about users that cannot run sudo.
- **Man pages** — lesson 1 teaches `man CMD`. Normal Ubuntu/Debian installs
  have them; minimal and container images strip them (install `man-db` and
  `manpages`).
- **A reachable package index for lesson 7** — the learner runs
  `apt update && apt install cowsay`. That is the only lesson that needs
  the network; on an offline lab, pre-install `cowsay` or skip lesson 7.
- **The tools the lessons use** — `acl` (`getfacl`/`setfacl`, lesson 19),
  `iputils-ping` (`ping`, lesson 12), `dnsutils`, `iproute2` and
  `netcat-openbsd` (lesson 23), `openssh-server` (lesson 22), `cron`
  (lesson 21), plus the usual `coreutils`, `gawk`, `sed`, `grep`, `procps`,
  `less`, `tar`, `zip`/`unzip`, `gzip`, `file` and `curl`.

The `Dockerfile` installs all of the above, so the container is a
known-good lab. `scripts/test.sh --lab` fails if any advertised command is
missing or if `man` does not render pages.

## Running a class

1. Provision one lab VM per learner (or one shared VM with
   `LAB_USERS="alice bob carol"` — each gets their own hidden files and
   progress state).
2. Install: `sudo ./scripts/install.sh`

   install.sh adds every lab user to the `adm` and `systemd-journal`
   groups — without them `journalctl -u lesson20` hides the flag and
   lesson 20 cannot be completed. It also warns when systemd is not
   running or a learner has no sudo rights; lessons 4, 20, 22, 23 and 24
   require sudo.
3. Tell learners: log in, type `ctf start`, read, solve, submit.
4. Check progress any time: `sudo ctf status` won't work for other
   users — instead read `~user/.ctf_state/` (progress, score, hints,
   attempts) or have learners run `ctf score`.

## Grading

- `ctf score` shows XP and per-lesson status. XP is self-reported by
  the game state; skill validators are the real proof of work.
- Hints used are logged in `~/.ctf_state/hints` — visible in `ctf score`.
- Want to force honesty? Watch the validators: `validate_lesson <n>`
  checks the artifact each lesson must produce.

## Resetting

- One lesson: `ctf reset 7` (learner-side)
- Everything: `ctf reset all`
- Instructor-side wipe of a user: remove their `~/.ctf_state` and the
  lesson artifacts (`.lesson2/`, `get_flag4.sh`, `project3/`,
  `lesson*` files).

## Answer key

`tests/solves/lessonNN.sh` — each is a scripted, minimal solution. Run
them on the lab machine as the learner user to reproduce any challenge
end-to-end. (Also what CI runs.) Solvers are idempotent — running one
twice is safe, and `scripts/test.sh --lab` re-runs all 24 to prove it.

## Repository checks

```bash
./scripts/test.sh              # lint: bash -n, invariants, shellcheck
./scripts/check-invariants.sh  # flag/hash sync, hint format, solver coverage, ...
```

The invariant checker exists because a broken check is worse than no
check: it verifies that flags match their hashes, that no flag value
leaks into lesson text, that every lesson still has a solver and a
validator case, and that install/uninstall stay symmetric.

## Timing guide

| Lesson | Expected time |
|--------|---------------|
| 1–5 | 10–20 min each |
| 6–9 | 15–25 min each |
| 10–12 | 20–40 min each |
| 13–18 | 20–40 min each |
| 19–23 | 25–45 min each |
| 24 (capstone) | 45–90 min |

Total: roughly 10–16 hours, fundamentals-only (1–12): 4–6 hours.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `ctf` not found | `sudo ./scripts/install.sh` again; check `/usr/local/bin` in PATH |
| Lesson 6 flag never appears | `sudo systemctl status lesson6-logger` — restart if dead |
| Lesson 8/19 "not readable" | new login shell after install (`newgrp ctf8`) |
| Lesson 12/23 unreachable | `sudo systemctl status lesson12-server lesson23-server` |
| Lesson 20 already active | `sudo systemctl stop lesson20 && sudo systemctl disable lesson20` then have the learner redo it |
| Lesson 20 journal empty | the learner is missing `adm`/`systemd-journal`; re-run `sudo ./scripts/install.sh` (it grants them) and log in again |
| Lesson 22 ssh refused | `sudo systemctl status ssh`; key must be in `/home/ctf22/.ssh/authorized_keys` |

## Extending the course

- Add lesson 25+: create `image/opt/lessons/lesson25.txt`,
  `..._min.txt`, `..._hints.txt`, flag + hash, a `validate_lesson` case,
  and `tests/solves/lesson25.sh`. Bump `LAST_LESSON` in
  `image/usr/local/bin/ctf` and the seq range in `scripts/test.sh`.
