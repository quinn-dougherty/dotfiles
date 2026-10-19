#!/usr/bin/env bash
# Install a managed Chromium policy that blocks x.com / twitter.com. Managed
# policies live in /etc and can't be overridden from chrome://settings, which
# is the point -- undoing it should take a sudo, not a click.
#
# URLBlocklist entries use Chromium's URL-filter format, not globs: a bare
# host matches every scheme, port, path and subdomain of it.
set -euo pipefail

policy_dir=/etc/chromium/policies/managed

sudo install -d -m 755 "$policy_dir"
sudo tee "$policy_dir/blocklist.json" >/dev/null <<'EOF'
{
  "URLBlocklist": [
    "x.com",
    "twitter.com"
  ]
}
EOF
sudo chmod 644 "$policy_dir/blocklist.json"
