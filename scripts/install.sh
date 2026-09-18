#!/usr/bin/env bash
set -euo pipefail

# install.sh — installs the Linux Fundamentals CTF into a lab machine.
# Idempotent: safe to run more than once.
#
#   sudo ./scripts/install.sh                     # install for $SUDO_USER
#   sudo LAB_USERS="alice bob" ./scripts/install.sh   # install for several users

if [[ $(id -u) -ne 0 ]]; then
  echo "Please run with sudo: sudo bash $0" >&2
  exit 1
fi

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
IMAGE_DIR="$ROOT_DIR/image"
USERS=()
if [[ -n "${LAB_USERS:-}" ]]; then
  for u in $LAB_USERS; do USERS+=("$u"); done
elif [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  USERS+=("$SUDO_USER")
fi

echo "[+] Preflight"
if ! command -v systemctl >/dev/null 2>&1 || [[ ! -d /run/systemd/system ]]; then
  echo "    WARNING: systemd does not appear to be running here."
  echo "             Lessons 6, 12, 20 and 23 rely on systemd services and"
  echo "             will not work until this course runs on a systemd host."
fi
if ! command -v sudo >/dev/null 2>&1; then
  echo "    WARNING: sudo is not installed."
  echo "             Lessons 4, 20, 22, 23 and 24 require it."
fi
for u in "${USERS[@]}"; do
  # NOTE: `sudo -l -U` exits 0 even for users without sudo rights, so the
  # policy text is what tells the two cases apart.
  sudo_policy=$(sudo -l -U "$u" 2>&1 || true)
  if [[ $sudo_policy == *"is not allowed to run sudo"* ]]; then
    echo "    WARNING: $u has no sudo rights on this machine."
    echo "             Lessons 4, 20, 22, 23 and 24 require sudo."
  fi
done

echo "[+] Copying course tree to /"
cp -a "$IMAGE_DIR/." /

echo "[+] Base permissions"
for b in ctf lessons lesson hint submit_flag check_flag progress validate_lesson \
         start-game start-learning ctf-welcome lesson6-logger.sh lesson7_checker \
         lesson12_server.py lesson16_worker.sh lesson20_flag.sh lesson21_checker \
         lesson23_server.py; do
  chmod 0755 "/usr/local/bin/$b" 2>/dev/null || true
done
chmod 0644 /opt/lessons/*.txt 2>/dev/null || true
chmod 0644 /opt/ctf/welcome.txt || true
chmod 0755 /opt/tools/lesson9_flag.sh 2>/dev/null || true
ln -sf lesson9_flag.sh /opt/tools/lesson9_flag || true

echo "[+] Flag storage"
# Lessons where reading the file IS the challenge keep readable flags;
# everything else is root-only and reachable through the challenge.
chmod 0644 /opt/flags/lesson1.flag
chmod 0600 /opt/flags/lesson2.flag /opt/flags/lesson3.flag /opt/flags/lesson5.flag \
           /opt/flags/lesson6.flag /opt/flags/lesson7.flag /opt/flags/lesson9.flag \
           /opt/flags/lesson10.flag /opt/flags/lesson11.flag /opt/flags/lesson12.flag \
           /opt/flags/lesson13.flag /opt/flags/lesson15.flag /opt/flags/lesson16.flag \
           /opt/flags/lesson17.flag /opt/flags/lesson18.flag /opt/flags/lesson20.flag \
           /opt/flags/lesson21.flag /opt/flags/lesson22.flag /opt/flags/lesson23.flag \
           /opt/flags/lesson24.flag || true
chmod 0600 /opt/flags/lesson4.flag
chmod 0640 /opt/flags/lesson8.flag
chmod 0644 /opt/flags/lesson14.flag
chmod 0640 /opt/flags/lesson19.flag
chown root:root /opt/flags/*.flag || true
chmod 0644 /opt/flags/.hashes/*.sha256

echo "[+] Groups"
groupadd -f ctf8
groupadd -f ctf19
groupadd -f ctf21
chown root:ctf8  /opt/flags/lesson8.flag
chown root:root /opt/flags/lesson14.flag
chown root:ctf19 /opt/flags/lesson19.flag

echo "[+] Lesson 19 shared directory (setgid)"
# Created after the blanket chown below; see "Challenge data permissions".

echo "[+] Lesson 21 spool (world-writable, sticky)"
install -d -m 1777 /var/spool/lesson21
touch /var/spool/lesson21/submissions.log
chmod 0666 /var/spool/lesson21/submissions.log

echo "[+] Lesson 22 remote account (ctf22)"
if ! id ctf22 >/dev/null 2>&1; then
  useradd -m -s /bin/bash ctf22
fi
install -d -m 0700 -o ctf22 -g ctf22 /home/ctf22/.ssh
touch /home/ctf22/.ssh/authorized_keys
chown ctf22:ctf22 /home/ctf22/.ssh/authorized_keys
chmod 0600 /home/ctf22/.ssh/authorized_keys
printf '%s\n' 'FLAG{lesson_22_ssh_commander}' > /home/ctf22/flag.txt
chown ctf22:ctf22 /home/ctf22/flag.txt
chmod 0600 /home/ctf22/flag.txt
chsh -s /bin/bash ctf22 2>/dev/null || true
passwd -l ctf22 2>/dev/null || true

echo "[+] Challenge data permissions"
chmod 0644 /opt/challenges/lesson14/source.txt
chmod 0644 /opt/challenges/lesson15/* 2>/dev/null || true
chmod 0755 /opt/challenges/lesson16/worker.sh
chmod 000  /opt/challenges/lesson24/pieces.csv
chmod 0644 /opt/challenges/lesson24/stage1 /opt/challenges/lesson24/dead_drop.txt
chown -R root:root /opt/challenges
# Re-apply the setgid shared dir (the blanket chown above resets it)
install -d -m 2770 -o root -g ctf19 /opt/challenges/lesson19/shared

echo "[+] Services"
systemctl daemon-reload 2>/dev/null || true
systemctl enable --now lesson6-logger.service || true
systemctl enable --now lesson12-server.service || true
systemctl enable --now lesson23-server.service || true
# Lesson 20 must start stopped and disabled — the learner starts it.
systemctl disable --now lesson20.service 2>/dev/null || true

echo "[+] Per-user setup"
for u in "${USERS[@]}"; do
  uh=$(getent passwd "$u" | cut -d: -f6)
  [[ -n "$uh" && -d "$uh" ]] || continue
  echo "    user: $u ($uh)"

  # Lesson 2: hidden directory + flag
  install -d -m 0700 -o "$u" -g "$u" "$uh/.lesson2"
  printf '%s\n' 'FLAG{lesson_02_paths_master}' > "$uh/.lesson2/flag.txt"
  chown "$u:$u" "$uh/.lesson2/flag.txt"
  chmod 0600 "$uh/.lesson2/flag.txt"

  # Lesson 4: wrapper script without execute bit
  cat > "$uh/get_flag4.sh" <<'EOS'
#!/usr/bin/env bash
set -euo pipefail
cat /opt/flags/lesson4.flag
EOS
  chown "$u:$u" "$uh/get_flag4.sh"
  chmod 0644 "$uh/get_flag4.sh"

  # Group memberships. adm/systemd-journal are required by lesson 20:
  # without them `journalctl -u lesson20` hides system messages, so the
  # learner can neither find the flag nor re-validate the lesson.
  groups="ctf8,ctf19,ctf21"
  for g in adm systemd-journal; do
    if getent group "$g" >/dev/null; then
      groups="$groups,$g"
    fi
  done
  usermod -aG "$groups" "$u" || true

  # State dir
  install -d -m 0700 -o "$u" -g "$u" "$uh/.ctf_state" || true
done

echo
echo "[+] Installed. Try:  ctf start"
echo "    Tip: new group memberships apply in a fresh login shell."
