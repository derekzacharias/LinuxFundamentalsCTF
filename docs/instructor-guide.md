# Instructor Guide

## Running a class

1. Provision one lab VM per learner (or one shared VM with
   `LAB_USERS="alice bob carol"` — each gets their own hidden files and
   progress state).
2. Install: `sudo ./scripts/install.sh`
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
end-to-end. (Also what CI runs.)

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
| Lesson 22 ssh refused | `sudo systemctl status ssh`; key must be in `/home/ctf22/.ssh/authorized_keys` |

## Extending the course

- Add lesson 25+: create `image/opt/lessons/lesson25.txt`,
  `..._min.txt`, `..._hints.txt`, flag + hash, a `validate_lesson` case,
  and `tests/solves/lesson25.sh`. Bump `LAST_LESSON` in
  `image/usr/local/bin/ctf` and the seq range in `scripts/test.sh`.
