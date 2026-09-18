# Repository Guidelines

> Contributor guide for LinuxFundamentalsCTF. Keep changes small,
> auditable, and reproducible.

## Project Structure
- `image/` everything installed onto the lab machine (`/opt/lessons`,
  `/opt/flags`, `/opt/data`, `/opt/challenges`, `/usr/local/bin`,
  systemd units). This is the product.
- `tests/solves/` one scripted student solution per lesson — the answer
  key AND the CI simulation. Any lesson change must keep its solver in sync.
- `scripts/` install.sh (idempotent), uninstall.sh, test.sh (lint + lab).
- `docs/` design, curriculum, instructor guide.

## Rules
1. **Flags never appear in lesson text.** Lesson files teach; flags live
   in `/opt/flags` (+ SHA-256 hashes in `/opt/flags/.hashes`). If you
   add/change a flag, update both the flag file and its hash, and keep
   the value consistent everywhere (lesson, validator, solver, data).
2. **Every lesson needs four files:** `lessonN.txt`, `lessonN_min.txt`,
   `lessonN_hints.txt` (3 hints, `HINT n |` format), plus a flag + hash.
3. **Every lesson needs three checks:** a `validate_lesson` case
   (skill artifacts, not just flag), a `tests/solves/lessonNN.sh`, and
   an entry in `ctf`'s lesson range.
4. **Challenges must be solvable non-interactively** — CI runs the
   solvers headless. No `read`, no editor-only steps, no prompts.
5. Hints escalate: level 1 = concept nudge, 2 = concrete command,
   3 = full answer.
6. install.sh must stay idempotent; uninstall.sh removes everything
   install.sh adds.

## Build, Test, and Development Commands
- `./scripts/test.sh` — lint (bash -n + `check-invariants.sh` + shellcheck)
- `sudo ./scripts/test.sh --lab` — end-to-end on an installed lab
  (solves + validates all 24 lessons, plus journal-access, game-loop,
  reset-integrity, CLI-stderr and solver re-run checks)
- `sudo ./scripts/test.sh --uninstall` — removes the lab, then asserts
  nothing was left behind (run in a throwaway container/VM)
- `docker build -t linux-ctf-lab . && docker run -d --privileged --name lab linux-ctf-lab`
  then `docker exec lab bash -c "cd /opt/LinuxFundamentalsCTF && ./scripts/test.sh --lab student"`
- `bash -n <file>` for quick syntax checks

## Flag inventory (source of truth: image/opt/flags/)
lesson_01_welcome_to_linux, lesson_02_paths_master, lesson_03_file_ops,
lesson_04_permissions_ftw, lesson_05_pipe_master, lesson_06_ps_master,
lesson_07_apt_pro, lesson_08_group_power, lesson_09_path_master,
lesson_10_script_novice, lesson_11_search_wizard, lesson_12_network_ready,
lesson_13_archive_archaeologist, lesson_14_link_master,
lesson_15_quote_unquote, lesson_16_signal_sergeant,
lesson_17_stream_sculptor, lesson_18_regex_raider, lesson_19_acl_ace,
lesson_20_systemd_savvy, lesson_21_cron_crusader, lesson_22_ssh_commander,
lesson_23_net_operative, lesson_24_breach_contained
