#!/usr/bin/env bash
set -euo pipefail
grep -q 'PATH=.*opt/tools' ~/.bashrc 2>/dev/null || echo 'export PATH="/opt/tools:$PATH"' >> ~/.bashrc
export PATH="/opt/tools:$PATH"
lesson9_flag
