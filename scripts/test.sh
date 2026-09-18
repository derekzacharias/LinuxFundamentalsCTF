#!/usr/bin/env bash
set -euo pipefail

# test.sh — repository checks.
#
#   ./scripts/test.sh            lint mode (any user): bash -n + invariants
#                                + shellcheck (errors fail, warnings reported)
#   sudo ./scripts/test.sh --lab [USER]   lab mode (inside installed lab):
#                                run every lesson solver as USER, then
#                                validate_lesson + check_flag for all 24,
#                                plus the game-loop/regression checks
#   sudo ./scripts/test.sh --uninstall    destructive: removes the lab with
#                                uninstall.sh, then asserts nothing remains
#                                (run in a throwaway container/VM)

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LAB_USER="${2:-${SUDO_USER:-$(id -un)}}"

lint() {
  local fails=0 f out
  local -a shell_files=()

  # Shell-family sources: *.sh plus every extensionless script with a
  # bash/sh shebang (ctf, validate_lesson, check_flag, ... all live there).
  while IFS= read -r f; do
    case "$(basename "$f")" in
      *.sh) shell_files+=("$f"); continue ;;
    esac
    if head -n1 "$f" 2>/dev/null | grep -qE '^#!.*(/|env )(bash|sh)([[:space:]]|$)'; then
      shell_files+=("$f")
    fi
  done < <(find "$ROOT_DIR" -type f ! -path '*/.git/*' ! -name '*.py' ! -name '*.service' ! -name '*.csv' ! -name '*.log' ! -name '*.bin' ! -name '*.txt' ! -name '*.md' ! -name '*.json' ! -name '*.yml' | sort)

  echo "== lint: bash -n (${#shell_files[@]} shell files)"
  for f in "${shell_files[@]}"; do
    bash -n "$f" || fails=$((fails+1))
  done
  echo "   syntax checked"

  echo "== lint: repository invariants"
  "$ROOT_DIR/scripts/check-invariants.sh" || fails=$((fails+1))

  if command -v shellcheck >/dev/null 2>&1; then
    echo "== lint: shellcheck (error level fails, warnings are informational)"
    for f in "${shell_files[@]}"; do
      out=$(shellcheck -S error -f gcc "$f" 2>&1) || true
      if [[ -n "$out" ]]; then
        printf '%s\n' "$out"
        echo "   ^ shellcheck error in $f"
        fails=$((fails+1))
      fi
    done
    for f in "${shell_files[@]}"; do
      shellcheck -S warning -f gcc "$f" 2>&1 | sed 's/^/   warn: /' || true
    done
    echo "   shellcheck done"
  else
    echo "== lint: shellcheck not installed — skipping"
  fi

  if (( fails > 0 )); then
    echo
    echo "== lint FAILED ($fails check(s))"
    exit 1
  fi
  echo "== lint OK"
}

lab() {
  echo "== lab mode: running as $LAB_USER"
  local fails=0

  for n in $(seq 1 24); do
    printf 'lesson %02d: ' "$n"
    solver="$ROOT_DIR/tests/solves/lesson$(printf '%02d' "$n").sh"
    [[ -f $solver ]] || { echo "MISSING SOLVER"; fails=$((fails+1)); continue; }

    flag=$(sudo -H -u "$LAB_USER" timeout 60 bash "$solver" </dev/null 2>/dev/null | grep -oE 'FLAG\{[^}]*\}' | tail -1 || true)
    if [[ -z "$flag" ]]; then
      echo "SOLVER FAILED (no flag output)"
      fails=$((fails+1))
      continue
    fi

    if ! sudo -H -u "$LAB_USER" /usr/local/bin/check_flag "$n" "$flag" >/dev/null 2>&1; then
      echo "FLAG MISMATCH (got $flag)"
      fails=$((fails+1))
      continue
    fi

    if ! sudo -H -u "$LAB_USER" /usr/local/bin/validate_lesson "$n" >/dev/null 2>&1; then
      echo "VALIDATE FAILED — details:"
      sudo -H -u "$LAB_USER" /usr/local/bin/validate_lesson "$n" 2>&1 | sed 's/^/    /' || true
      fails=$((fails+1))
      continue
    fi

    echo "PASS"
  done

  echo
  if (( fails > 0 )); then
    echo "== $fails lesson(s) FAILED"
    exit 1
  fi

  # ---- lesson20 regression: install.sh must grant direct journal access ----
  # (a lab user without adm/systemd-journal sees no system journal entries,
  #  which makes lesson 20 unsolvable on any real install)
  echo "== journal access check (lesson 20 on a real install)"
  if ! sudo -H -u "$LAB_USER" bash -c 'journalctl -u lesson20 --no-pager -n 200 2>/dev/null | grep -q "FLAG{lesson_20"'; then
    echo "   FAIL: $LAB_USER cannot read lesson20's journal without root."
    echo "         install.sh must add lab users to adm/systemd-journal."
    exit 1
  fi
  echo "   journal access: PASS"

  # ---- game-loop regression: the real player path (ctf submit + state) ----
  echo "== game-loop check (ctf submit end to end)"
  sudo -H -u "$LAB_USER" ctf reset all >/dev/null 2>&1 || true
  if ! sudo -H -u "$LAB_USER" ctf submit 1 'FLAG{lesson_01_welcome_to_linux}' >/dev/null 2>&1; then
    echo "   game-loop: ctf submit FAILED"
    exit 1
  fi
  if ! sudo -H -u "$LAB_USER" bash -c 'ctf status | grep -q "Lessons:.*1 / 24"'; then
    echo "   game-loop: progress not recorded"
    exit 1
  fi
  if ! sudo -H -u "$LAB_USER" bash -c 'ctf status | grep -q "XP:.*100 / 2400"'; then
    echo "   game-loop: XP not awarded"
    exit 1
  fi
  echo "   game-loop: PASS"

  # ---- reset integrity: reset + redo must be XP-neutral ----
  # Two lessons are needed: with a bare lesson the score clamps at 0 and the
  # old flat -100 withdrawal would be invisible. Baseline = 100 (L1 clean),
  # then L2 with hint 3 = +80. Old code: 180 -> 80 -> 160. New: 180 -> 100 -> 180.
  echo "== reset integrity check (hint penalty must not double-dip)"
  xp() { sudo -H -u "$LAB_USER" bash -c 'cat ~/.ctf_state/score 2>/dev/null || echo 0'; }
  flag2=$(sudo -H -u "$LAB_USER" bash -c 'cat ~/.lesson2/flag.txt')
  sudo -H -u "$LAB_USER" ctf reset all >/dev/null 2>&1 || true
  sudo -H -u "$LAB_USER" ctf submit 1 'FLAG{lesson_01_welcome_to_linux}' >/dev/null 2>&1
  sudo -H -u "$LAB_USER" ctf hint 2 3 >/dev/null 2>&1
  sudo -H -u "$LAB_USER" ctf submit 2 "$flag2" >/dev/null 2>&1
  xp_hinted=$(xp)
  sudo -H -u "$LAB_USER" ctf reset 2 >/dev/null 2>&1
  xp_reset=$(xp)
  sudo -H -u "$LAB_USER" ctf submit 2 "$flag2" >/dev/null 2>&1
  xp_redo=$(xp)
  sudo -H -u "$LAB_USER" ctf reset all >/dev/null 2>&1 || true
  if [[ "$xp_hinted" != "180" || "$xp_reset" != "100" || "$xp_redo" != "180" ]]; then
    echo "   FAIL: hint-3 solve/reset/redo gave $xp_hinted/$xp_reset/$xp_redo (want 180/100/180)"
    exit 1
  fi
  echo "   reset integrity: PASS (hint-3 lesson: 180 -> reset -> 180)"

  # ---- the lab must provide every command the lessons teach ----
  echo "== toolbelt check (commands advertised by the lessons)"
  local missing
  missing=$(sudo -H -u "$LAB_USER" bash -s <<'TOOLS'
for c in man ping getfacl setfacl ss dig host getent nc curl ssh ssh-keygen scp \
         crontab systemctl journalctl tar gzip zip unzip file base64 sed awk paste tr cut \
         less readlink stat find ps top kill df du env printenv id groups newgrp sudo \
         apt dpkg chmod chown ln touch mkdir cp mv rm wc head tail sort; do
  command -v "$c" >/dev/null 2>&1 || printf '%s ' "$c"
done
TOOLS
)
  if [[ -n "${missing// /}" ]]; then
    echo "   FAIL: lessons teach commands that this lab does not have: $missing"
    exit 1
  fi
  # man must render a real page, not Ubuntu's "system has been minimized" stub
  if ! sudo -H -u "$LAB_USER" bash -c 'man ls 2>/dev/null | grep -q "LS(1)"'; then
    echo "   FAIL: 'man' does not render man pages (lesson 1 teaches it)"
    exit 1
  fi
  echo "   toolbelt: PASS"

  # ---- UX: player-facing commands must not leak stray stderr ----
  echo "== CLI stderr check (no awk/grep warnings on the player path)"
  for args in list map status score "brief 5" "open 5" "hint 5 1" "hint 5 3" next help; do
    read -r -a argv <<< "$args"
    # </dev/null keeps 'ctf open' from launching less on an interactive host
    stderr=$(sudo -H -u "$LAB_USER" ctf "${argv[@]}" </dev/null 2>&1 >/dev/null || true)
    if [[ -n "$stderr" ]]; then
      echo "   FAIL: 'ctf $args' wrote to stderr:"
      printf '%s\n' "$stderr" | sed 's/^/     /'
      exit 1
    fi
  done
  sudo -H -u "$LAB_USER" ctf reset all >/dev/null 2>&1 || true
  echo "   CLI stderr: PASS"

  # ---- the answer key must be re-runnable (instructors re-run solvers) ----
  echo "== solver re-run check (answer key is idempotent)"
  local rerun_fails=0 n solver out
  for n in $(seq 1 24); do
    printf 'lesson %02d: ' "$n"
    solver="$ROOT_DIR/tests/solves/lesson$(printf '%02d' "$n").sh"
    out=$(sudo -H -u "$LAB_USER" timeout 60 bash "$solver" </dev/null 2>/dev/null || true)
    if ! grep -qE 'FLAG\{[^}]*\}' <<< "$out"; then
      echo "RE-RUN FAILED (solver is not idempotent)"
      rerun_fails=$((rerun_fails+1))
      continue
    fi
    echo "PASS"
  done
  if (( rerun_fails > 0 )); then
    echo "   $rerun_fails solver(s) cannot be run twice"
    exit 1
  fi
  echo "   solver re-run: PASS"

  echo
  echo "== all 24 lessons PASS"
}

uninstall_check() {
  echo "== uninstall mode (run as root on a freshly installed lab)"
  local fails=0 path g

  if ! "$ROOT_DIR/scripts/uninstall.sh"; then
    echo "   FAIL: uninstall.sh exited non-zero"
    exit 1
  fi

  # Everything install.sh creates must be gone. This list is deliberately
  # independent of uninstall.sh's own list: an oracle derived from the code
  # under test cannot fail.
  for path in /opt/lessons /opt/flags /opt/data /opt/challenges /opt/ctf /opt/tools \
              /usr/local/bin/ctf /usr/local/bin/lesson /usr/local/bin/lessons \
              /usr/local/bin/hint /usr/local/bin/submit_flag /usr/local/bin/check_flag \
              /usr/local/bin/progress /usr/local/bin/validate_lesson /usr/local/bin/start-game \
              /usr/local/bin/start-learning /usr/local/bin/ctf-welcome \
              /usr/local/bin/lesson6-logger.sh /usr/local/bin/lesson7_checker \
              /usr/local/bin/lesson12_server.py /usr/local/bin/lesson16_worker.sh \
              /usr/local/bin/lesson20_flag.sh /usr/local/bin/lesson21_checker \
              /usr/local/bin/lesson23_server.py \
              /etc/systemd/system/lesson6-logger.service /etc/systemd/system/lesson12-server.service \
              /etc/systemd/system/lesson20.service /etc/systemd/system/lesson23-server.service \
              /var/spool/lesson21 /var/log/lesson6.log /var/log/lesson12_access.log \
              /home/ctf22; do
    if [[ -e $path ]]; then
      echo "   FAIL: $path survived uninstall"
      fails=$((fails+1))
    fi
  done

  for g in ctf8 ctf19 ctf21 ctf22; do
    if getent group "$g" >/dev/null; then
      echo "   FAIL: group $g survived uninstall"
      fails=$((fails+1))
    fi
  done
  if id ctf22 >/dev/null 2>&1; then
    echo "   FAIL: user ctf22 survived uninstall"
    fails=$((fails+1))
  fi

  # The learner CLIs must no longer resolve.
  if command -v ctf >/dev/null 2>&1; then
    echo "   FAIL: 'ctf' is still on PATH"
    fails=$((fails+1))
  fi
  if systemctl list-unit-files 'lesson*.service' --no-legend 2>/dev/null | grep -q lesson; then
    echo "   FAIL: lesson units are still known to systemd"
    fails=$((fails+1))
  fi

  echo
  if (( fails > 0 )); then
    echo "== uninstall FAILED ($fails leftover(s))"
    exit 1
  fi
  echo "== uninstall clean — nothing left behind"
}

case "${1:-lint}" in
  lint) lint ;;
  --lab) lab ;;
  --uninstall) uninstall_check ;;
  *) echo "Usage: $0 [lint|--lab [USER]|--uninstall]" >&2; exit 2 ;;
esac
