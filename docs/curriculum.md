# Linux Fundamentals CTF — Curriculum

Two acts, 24 lessons. Every lesson: read the OBJECTIVE, study LEARN, solve the TASK, submit the flag.

## Act I — Fundamentals

| # | Lesson | Skills | Flag file (storage) |
|---|--------|--------|---------------------|
| 1 | Orientation & first flag | `whoami`, `hostname`, `pwd`, `ls`, `cat`, `man`, `--help` | `/opt/flags/lesson1.flag` (0644) |
| 2 | Paths & hidden files | `cd`, `ls -a`, `~`, `.`, `..`, absolute vs relative | `~/.lesson2/flag.txt` (0600, created at install) |
| 3 | File operations | `touch`, `mkdir`, `cp`, `mv`, `rm`, globs, concatenation | assembled by learner in `~/project3` |
| 4 | Permissions & ownership | `ls -l`, `chmod`, execute bit, `sudo` | `/opt/flags/lesson4.flag` (0600 root) |
| 5 | Text, redirection, pipes | `cat`, `less`, `head`, `tail`, `grep`, `wc`, `>`, `>>`, `|` | `/opt/data/lesson5_data.txt` |
| 6 | Processes & logs | `ps`, `grep`, `kill`, `tail -f`, background services | `/var/log/lesson6.log` (service writes it) |
| 7 | Package management | `apt update`, `apt install`, `apt show`, `dpkg -l` | printed by `lesson7_checker` |
| 8 | Users, groups, sudo | `id`, `groups`, `ls -l`, `newgrp`, `sudo -l` | `/opt/flags/lesson8.flag` (0640 root:ctf8) |
| 9 | PATH & environment | `env`, `printenv`, `$PATH`, `~/.bashrc`, `source` | `/opt/tools/lesson9_flag.sh` |
| 10 | Bash scripting I | variables, `$1`, `if`, `for`, `chmod +x`, `find`, `wc -l` | `/opt/data/lesson10_logs/app4.log` (computed) |
| 11 | find & grep | `find`, `grep -R`, `df -h`, `du -sh`, `wc -l` | `/opt/data/lesson11/secret_info.txt` |
| 12 | Networking basics | `ip a`, `curl`, `ss -tlnp`, local HTTP services | served by lesson12-server (localhost:8080) |

## Act II — Intermediate

| # | Lesson | Skills | Flag storage |
|---|--------|--------|--------------|
| 13 | Archives & compression | `tar`, `gzip`, `gunzip`, `zip`, `unzip`, `tar -tzf` | inside nested archives in `/opt/challenges/lesson13` |
| 14 | Symbolic & hard links | `ln -s`, `ln`, `readlink`, `stat`, inodes, link counts | symlink chain in `/opt/challenges/lesson14` |
| 15 | Shell expansion & quoting | globs, brace/parameter/command expansion, quoting, escaping | file with metacharacters in its name |
| 16 | Job control & signals | `&`, `bg`, `fg`, `jobs`, `ps`, `kill`, `trap`, `SIGUSR1` | written by `~/lesson16_worker.sh` after signal |
| 17 | sed & awk | `sed` substitutions/ranges, `awk` fields, CSV processing | column of `/opt/data/lesson17/payload.csv` |
| 18 | Regex & grep mastery | `grep -oE`, character classes, anchors, `-P`, context flags | fragments in `/opt/data/lesson18/access.log` |
| 19 | Permissions & ACLs deep dive | `umask`, setgid dirs, sticky bit, `getfacl`, `setfacl`, `chown` | `/opt/flags/lesson19.flag` (0640 root:ctf19) |
| 20 | systemd | `systemctl`, `journalctl`, unit files, enable/start, boot status | journal of `lesson20.service` |
| 21 | cron & scheduling | `crontab -e`, schedule syntax, `cron.d`, checking `journalctl` for cron | printed by `lesson21_checker` |
| 22 | SSH & remote access | `ssh-keygen`, `authorized_keys`, `ssh`, `scp`, key auth | `/home/ctf22/flag.txt` (0600 ctf22) |
| 23 | Networking tools | `ss`, `dig`, `host`, `/etc/hosts`, `nc`, HTTP Host headers | served by lesson23-server (127.0.0.1:9099) |
| 24 | Capstone: the breach | combines 1–23: base64, tar, grep, sed/awk, links, permissions, cron, logs | assembled across 6 stages in `~/lesson24` |

## Learning objectives (condensed)

- **Navigation & files** (1–3, 14): move confidently, understand the tree, hidden files, paths, links, inodes.
- **Text mastery** (5, 17, 18): view, filter, transform, and extract — grep/sed/awk are the Linux Swiss army knife.
- **Permissions & identity** (4, 8, 19): read/write/execute, ownership, groups, umask, setuid/setgid/sticky, ACLs.
- **Processes & automation** (6, 16, 20, 21): see what runs, control it, signal it, and schedule it with systemd/cron.
- **System plumbing** (7, 9, 10): install software, shape your environment, and script repetitive work.
- **Networking & remote access** (12, 22, 23): inspect the stack, talk HTTP, move safely over SSH.
- **Synthesis** (11, 13, 15, 24): combine tools under pressure; the capstone proves it.

## Scoring

- Each lesson: **100 XP**. Course total: **2400 XP**.
- Hint 1: free. Hint 2: −10 XP. Hint 3: −20 XP (deducted when the lesson is completed).
- Wrong flag submission: −5 XP.
- Ranks: Shell Novice (0) → Terminal Rookie (100) → Command-line Adept (400) → Linux Operative (900) → Shell Hacker (1500) → Terminal Legend (2000) → Linux Master (2200).
- Finishing the course does **not** guarantee Master: hint 3 on every lesson costs 480 XP, so the worst reasonable run ends at 1920 XP (Shell Hacker). Master needs a near-clean run (≤200 XP of penalties). Wrong submissions cost 5 XP each and are not capped. `ctf reset <n>` withdraws exactly what that lesson awarded (100 minus its hint penalty), so resetting and redoing a lesson is XP-neutral.
