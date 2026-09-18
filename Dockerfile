# Linux Fundamentals CTF — lab container (Ubuntu + systemd)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo systemd systemd-sysv openssh-server python3 curl ca-certificates \
      unzip zip file coreutils gawk sed grep procps netcat-openbsd \
      iproute2 dnsutils less vim-tiny nano cowsay shellcheck rsync cron dbus policykit-1 \
    && rm -rf /var/lib/apt/lists/*

# Lab user with passwordless sudo (lab-only; never in production)
RUN useradd -m -s /bin/bash -G adm,systemd-journal student \
 && echo 'student ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/student \
 && chmod 440 /etc/sudoers.d/student

# SSH for lesson 22
RUN ssh-keygen -A

COPY . /opt/LinuxFundamentalsCTF

# Install the course. LAB_USERS=student so per-user artifacts land in ~student.
RUN cd /opt/LinuxFundamentalsCTF \
 && LAB_USERS=student ./scripts/install.sh

# Warm-up service that systemd needs (ensures the container stays up)
CMD ["/sbin/init"]
