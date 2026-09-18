#!/usr/bin/env bash
# NOTE: no `set -e` on purpose — this script collects every violation and
# reports them together instead of aborting at the first one.
set -uo pipefail

# check-invariants.sh — repository invariants that keep the course coherent.
# Needs no root and no installed lab; wired into scripts/test.sh (lint mode).
#
# Invariants (they encode AGENTS.md rules 1-3):
#   1. every lesson ships lessonN.txt + lessonN_min.txt + lessonN_hints.txt
#   2. every hints file has exactly HINT 1|2|3 and no other HINT lines
#   3. every flag file matches its SHA-256 hash
#   4. flag values never appear in lesson text (rule: flags never in lessons)
#   5. flag values only live where the design allows them
#   6. every lesson has an executable, non-interactive solver
#   7. validate_lesson covers exactly lessons 1..LAST and nothing else
#   8. LAST_LESSON, test.sh's range and the shipped lesson count agree
#   9. everything install.sh installs exists, and uninstall.sh removes all of it

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LESSONS="$ROOT_DIR/image/opt/lessons"
FLAGS="$ROOT_DIR/image/opt/flags"
SOLVES="$ROOT_DIR/tests/solves"
CTF="$ROOT_DIR/image/usr/local/bin/ctf"
VALIDATOR="$ROOT_DIR/image/usr/local/bin/validate_lesson"
INSTALL="$ROOT_DIR/scripts/install.sh"
UNINSTALL="$ROOT_DIR/scripts/uninstall.sh"

LAST=$(grep -oE '^LAST_LESSON=[0-9]+' "$CTF" | cut -d= -f2)
[[ -n "$LAST" ]] || { echo "FAIL: cannot read LAST_LESSON from $CTF" >&2; exit 1; }

fails=0
fail() { echo "  FAIL: $*" >&2; fails=$((fails+1)); }
pass() { echo "  OK:   $*"; }

# Flag values may live here — nowhere else. Lesson text is explicitly denied
# even though it lives under image/opt/lessons (AGENTS.md rule 1).
flag_allowed() {
  case "$1" in
    image/opt/flags/lesson*.flag) return 0 ;;
    image/opt/lessons/*)          return 1 ;;
    tests/solves/*)               return 0 ;;
    scripts/install.sh | scripts/test.sh | scripts/check-invariants.sh) return 0 ;;
    image/usr/local/bin/*)        return 0 ;;
    image/opt/data/* | image/opt/challenges/* | image/opt/tools/*) return 0 ;;
    *) return 1 ;;
  esac
}

echo "== invariants: lesson files and hints"
section_fails=$fails
for (( n = 1; n <= LAST; n++ )); do
  for f in "$LESSONS/lesson${n}.txt" "$LESSONS/lesson${n}_min.txt" "$LESSONS/lesson${n}_hints.txt"; do
    [[ -f $f ]] || fail "missing $(basename "$f")"
  done
  h="$LESSONS/lesson${n}_hints.txt"
  [[ -f $h ]] || continue
  mapfile -t levels < <(grep -oE '^HINT [123] \|' "$h" | awk '{print $2}')
  stray=$(grep -cE '^HINT' "$h" 2>/dev/null || echo 0)
  if [[ ${#levels[@]} -ne 3 || "${levels[*]}" != "1 2 3" ]]; then
    fail "lesson${n}_hints.txt must have exactly 'HINT 1 |', 'HINT 2 |', 'HINT 3 |'"
  fi
  (( stray == 3 )) || fail "lesson${n}_hints.txt has $stray lines starting with HINT (want 3)"
done
(( fails == section_fails )) && pass "all $LAST lessons ship txt + min + 3 well-formed hints"

echo "== invariants: flag files match their hashes"
section_fails=$fails
for (( n = 1; n <= LAST; n++ )); do
  ff="$FLAGS/lesson$n.flag"
  hf="$FLAGS/.hashes/lesson$n.sha256"
  [[ -f $ff ]] || { fail "missing $(basename "$ff")"; continue; }
  [[ -f $hf ]] || { fail "missing .hashes/lesson$n.sha256"; continue; }
  val=$(cat "$ff")
  want=$(tr -d '[:space:]' < "$hf")
  got=$(printf '%s' "$val" | sha256sum | awk '{print $1}')
  [[ "$want" == "$got" ]] || fail "lesson$n hash mismatch (flag edited without updating its hash?)"
done
(( fails == section_fails )) && pass "$LAST flag files match their SHA-256 hashes"

echo "== invariants: flag values stay in authorised places"
section_fails=$fails
# One grep with the flag values as a pattern file (instead of 24 x N greps)
# keeps this on the fast path while preserving exact substring semantics.
mapfile -t flag_values < <(for (( n = 1; n <= LAST; n++ )); do cat "$FLAGS/lesson$n.flag" 2>/dev/null; done)
pattern_file=$(mktemp)
printf '%s\n' "${flag_values[@]}" > "$pattern_file"
mapfile -t flag_hits < <(cd "$ROOT_DIR" && grep -rlFf "$pattern_file" --exclude-dir=.git . 2>/dev/null | sed 's|^\./||')
rm -f "$pattern_file"
for f in "${flag_hits[@]}"; do
  flag_allowed "$f" && continue
  for (( n = 1; n <= LAST; n++ )); do
    grep -qF -- "${flag_values[n-1]}" "$ROOT_DIR/$f" 2>/dev/null || continue
    fail "lesson $n flag value appears in $f"
  done
done
(( fails == section_fails )) && pass "no flag value leaks into lesson text or unauthorised files"

echo "== invariants: solvers"
section_fails=$fails
for (( n = 1; n <= LAST; n++ )); do
  s="$SOLVES/lesson$(printf '%02d' "$n").sh"
  [[ -f $s ]] || { fail "missing $(basename "$s")"; continue; }
  [[ -x $s ]] || fail "$(basename "$s") is not executable"
  if grep -qE '(^|[;&|()[:space:]])read([[:space:]]|$)' "$s"; then
    fail "$(basename "$s") prompts interactively (must run headless)"
  fi
done
(( fails == section_fails )) && pass "$LAST headless solvers present"

echo "== invariants: validator coverage"
section_fails=$fails
mapfile -t covered < <(grep -oE '^  [0-9]+\)' "$VALIDATOR" | tr -dc '0-9\n' | sort -n)
if [[ ${#covered[@]} -eq 0 ]]; then
  fail "validate_lesson exposes no numeric cases"
else
  missing=""
  for (( n = 1; n <= LAST; n++ )); do
    printf '%s\n' "${covered[@]}" | grep -qx "$n" || missing="$missing $n"
  done
  [[ -z "${missing// /}" ]] || fail "validate_lesson has no case for lesson(s):$missing"
  extra=$(printf '%s\n' "${covered[@]}" | awk -v last="$LAST" '$1 > last' | tr '\n' ' ')
  [[ -z "${extra// /}" ]] || fail "validate_lesson has cases beyond LAST_LESSON=$LAST:$extra"
fi
(( fails == section_fails )) && pass "validate_lesson covers exactly 1..$LAST"

echo "== invariants: lesson count agreement"
section_fails=$fails
shipped=$(find "$LESSONS" -maxdepth 1 -name 'lesson*_min.txt' | wc -l)
(( shipped == LAST )) || fail "shipped $shipped task cards but LAST_LESSON=$LAST"
mapfile -t ranges < <(grep -oE 'seq 1 [0-9]+' "$ROOT_DIR/scripts/test.sh" | awk '{print $3}' | sort -u)
for r in "${ranges[@]}"; do
  (( r == LAST )) || fail "scripts/test.sh iterates lessons 1..$r but LAST_LESSON=$LAST"
done
(( fails == section_fails )) && pass "ctf, task cards and test.sh all agree on $LAST lessons"

echo "== invariants: install/uninstall symmetry"
section_fails=$fails
while IFS= read -r unit; do
  [[ -f "$ROOT_DIR/image/etc/systemd/system/$unit" ]] || fail "install.sh enables missing unit $unit"
done < <(grep -oE '[a-z0-9-]+\.service' "$INSTALL" | sort -u)

for f in "$ROOT_DIR"/image/etc/systemd/system/*.service; do
  b=$(basename "$f")
  grep -qF "$b" "$UNINSTALL" || fail "uninstall.sh does not remove $b"
done

for f in "$ROOT_DIR"/image/usr/local/bin/*; do
  b=$(basename "$f")
  grep -qF "/usr/local/bin/$b" "$UNINSTALL" || fail "uninstall.sh does not remove /usr/local/bin/$b"
done

for d in "$ROOT_DIR"/image/opt/*/; do
  b=$(basename "$d")
  grep -qF "/opt/$b" "$UNINSTALL" || fail "uninstall.sh does not remove /opt/$b"
done

missing_bins=""
while IFS= read -r b; do
  [[ -n $b ]] || continue
  [[ -e "$ROOT_DIR/image/usr/local/bin/$b" ]] || missing_bins="$missing_bins $b"
done < <(awk '/^for b in ctf/,/; do$/' "$INSTALL" | sed 's/[\\;]//g' | tr ' ' '\n' | grep -vE '^(for|b|in|do)$' || true)
[[ -z "${missing_bins// /}" ]] || fail "install.sh references non-existent binaries:$missing_bins"
(( fails == section_fails )) && pass "install.sh binaries, units and uninstall removal paths all exist"

echo
if (( fails > 0 )); then
  echo "== invariants FAILED ($fails violation(s))"
  exit 1
fi
echo "== invariants OK"
