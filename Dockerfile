# Linux Fundamentals CTF — lab container (Ubuntu + systemd)
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo systemd systemd-sysv openssh-server python3 curl ca-certificates \
      unzip zip file coreutils gawk sed grep procps netcat-openbsd \
      iproute2 dnsutils less vim-tiny nano shellcheck rsync cron dbus policykit-1 \
    && rm -rf /var/lib/apt/lists/*

# A normal server has man pages and the tools the lessons teach; Ubuntu's
# minimized image strips man pages, diverts /usr/bin/man to a "system has
# been minimized" stub, and lacks acl/iputils-ping (lesson 19 teaches
# getfacl/setfacl, lesson 12 teaches ping). NOTE: cowsay is deliberately
# absent — installing it is lesson 7's task, and shipping it would make
# lesson7_checker pass without the learner touching apt.
RUN rm -f /etc/dpkg/dpkg.cfg.d/excludes \
 && dpkg-divert --remove --rename /usr/bin/man \
 && apt-get update \
 && apt-get install -y --no-install-recommends man-db manpages acl iputils-ping \
 && apt-get install -y --reinstall --no-install-recommends \
      coreutils bash tar gzip grep sed gawk findutils procps less \
      curl openssh-client zip unzip file cron systemd iproute2 dnsutils \
      netcat-openbsd sudo apt dpkg hostname \
 && rm -rf /var/lib/apt/lists/*

# Lab user with passwordless sudo (lab-only; never in production).
# NOTE: deliberately no extra groups here — install.sh must provision
# adm/systemd-journal itself, so CI exercises the same path a real lab
# machine takes. That is what makes lesson 20 work.
RUN useradd -m -s /bin/bash student \
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
