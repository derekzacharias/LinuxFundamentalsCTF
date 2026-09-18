# Linux Fundamentals CTF

Learn Linux **entirely from the command line** by playing a Capture the
Flag game. Two acts, 24 lessons, one shell — from `ls` to a six-stage
incident-response capstone.

```
 ctf start            → begin the game
 ctf status           → your rank, XP, next lesson
 ctf open 14          → study + challenge for lesson 14
 ctf hint 14 1        → unstuck (level 2/3 hints cost XP)
 ctf submit 14 FLAG{...}  → prove it (skill checks run automatically)
```

## How it works

Every lesson follows the same loop:

1. **OBJECTIVE** — what skill you are about to learn
2. **LEARN** — concepts and examples you can type and try
3. **TASK** — a challenge with deliberately *no* solution commands
4. **SUBMIT** — hand in the flag; the game verifies not just the flag,
   but that you *actually performed the skill* (file created, permission
   changed, service started, cron installed...)

Stuck? `ctf hint <n> 1` is free. Levels 2 and 3 cost 10/20 XP at lesson
completion. Wrong submissions cost 5 XP. 100 XP per lesson, 2400 total —
ranks from *Shell Novice* to *Linux Master*.

## Curriculum

| Act I — Fundamentals | Act II — Intermediate |
|---|---|
| 1 Orientation & first flag | 13 Archives & compression |
| 2 Paths & hidden files | 14 Symbolic & hard links |
| 3 File operations | 15 Shell expansion & quoting |
| 4 Permissions & ownership | 16 Job control & signals |
| 5 Text, redirection, pipes | 17 sed & awk |
| 6 Processes & logs | 18 Regex & grep mastery |
| 7 Package management | 19 Permissions & ACLs deep dive |
| 8 Users, groups, sudo | 20 systemd |
| 9 PATH & environment | 21 cron & scheduling |
| 10 Bash scripting I | 22 SSH & remote access |
| 11 find & grep | 23 Networking tools |
| 12 Networking basics | 24 CAPSTONE: the breach |

Full details: [docs/curriculum.md](docs/curriculum.md) ·
[design rationale](docs/design.md) · [instructor guide](docs/instructor-guide.md)

## Install (lab machine)

Dedicated VM or container — it installs flags, services, users and
challenge data system-wide.

```bash
sudo ./scripts/install.sh          # for the invoking user
sudo LAB_USERS="alice bob" ./scripts/install.sh   # for several users
```

Learners then log in and run `ctf start`. New shell required after
install so group memberships apply.

### Docker (instant lab)

```bash
docker build -t linux-ctf-lab .
docker run -d --privileged --name lab linux-ctf-lab
docker exec -it -u student lab bash -lc 'ctf start'
```

## Repository layout

```
docs/            design, curriculum, instructor guide
image/           everything installed onto the lab machine (/opt, /usr/local/bin, systemd units)
scripts/         install.sh, uninstall.sh, test.sh
tests/solves/    one scripted student solution per lesson (= instructor answer key)
Dockerfile       reproducible lab image (Ubuntu + systemd)
.github/         CI: lint + build lab + solve+validate all 24 lessons
```

## Development

```bash
./scripts/test.sh               # lint: bash -n + shellcheck
sudo ./scripts/test.sh --lab    # end-to-end: solves + validates all 24 lessons
```

## Security note

This is a **training lab**. It deliberately contains world-writable
directories, a passwordless-sudo lab user in the container, group-
sharing exercises, and a challenge account (`ctf22`). Never install it
on a machine you care about.
