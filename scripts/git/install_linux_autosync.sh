#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
unit_dir="$HOME/.config/systemd/user"
service_file="$unit_dir/myfit-git-sync.service"
timer_file="$unit_dir/myfit-git-sync.timer"
sync_script="$repo_root/scripts/git/sync_to_github.sh"

mkdir -p "$unit_dir"

cat > "$service_file" <<EOF
[Unit]
Description=Sync Myfit repository to GitHub

[Service]
Type=oneshot
WorkingDirectory=$repo_root
ExecStart=$sync_script
EOF

cat > "$timer_file" <<EOF
[Unit]
Description=Run Myfit git sync every 20 minutes

[Timer]
OnBootSec=5m
OnUnitActiveSec=20m
Unit=myfit-git-sync.service

[Install]
WantedBy=timers.target
EOF

chmod +x "$sync_script"
systemctl --user daemon-reload
systemctl --user enable --now myfit-git-sync.timer

echo "Installed myfit-git-sync.timer"
