#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run this command as root on the Proxmox VE host."; exit 1; }
command -v pct >/dev/null || { echo "ERROR: pct not found. Run this on a Proxmox VE host."; exit 1; }
APP_REPO="tuffysan/GmailAttachmentManager"
echo
echo "============================================================"
echo " Gmail Attachment Manager - Proxmox LXC Installer"
echo "============================================================"
echo
apt-get update -qq
apt-get install -y -qq curl jq ca-certificates >/dev/null
read -rsp "GitHub fine-grained read token for $APP_REPO: " GITHUB_TOKEN; echo
[[ -n "$GITHUB_TOKEN" ]] || { echo "ERROR: token is required while the application repository is private."; exit 1; }
if ! curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$APP_REPO" >/dev/null; then echo "ERROR: token cannot read $APP_REPO."; exit 1; fi
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.raw+json" "https://api.github.com/repos/$APP_REPO/contents/proxmox/create-lxc.sh?ref=main" -o "$TMP/create-lxc.sh"
chmod +x "$TMP/create-lxc.sh"
export GITHUB_TOKEN REPO="$APP_REPO"
"$TMP/create-lxc.sh"
CTID=$(ls -t /etc/gmail-attachment-manager/ct-*.conf 2>/dev/null | head -1 | sed -E 's/.*ct-([0-9]+)\.conf/\1/' || true)
install -d -m 755 /usr/local/lib/gmail-attachment-manager
for f in update-lxc.sh status-lxc.sh; do
  curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" -H "Accept: application/vnd.github.raw+json" "https://api.github.com/repos/$APP_REPO/contents/proxmox/$f?ref=main" -o "/usr/local/lib/gmail-attachment-manager/$f"
  chmod 755 "/usr/local/lib/gmail-attachment-manager/$f"
done
cat > /usr/local/bin/gmail-attachment-manager <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
CMD="${1:-status}"; ARG="${2:-}"
if [[ -z "$ARG" ]]; then
  mapfile -t CFG < <(ls /etc/gmail-attachment-manager/ct-*.conf 2>/dev/null || true)
  [[ ${#CFG[@]} -eq 1 ]] && ARG=$(basename "${CFG[0]}" | sed -E 's/ct-([0-9]+)\.conf/\1/')
fi
case "$CMD" in
 status) [[ -n "$ARG" ]] || { echo "Usage: gmail-attachment-manager status <CTID>"; exit 1; }; exec /usr/local/lib/gmail-attachment-manager/status-lxc.sh "$ARG";;
 update) [[ -n "$ARG" ]] || { echo "Usage: gmail-attachment-manager update <CTID>"; exit 1; }; exec /usr/local/lib/gmail-attachment-manager/update-lxc.sh "$ARG";;
 logs) [[ -n "$ARG" ]] || { echo "Usage: gmail-attachment-manager logs <CTID>"; exit 1; }; exec pct exec "$ARG" -- journalctl -u gmail-attachment-manager -n 150 --no-pager;;
 restart) [[ -n "$ARG" ]] || { echo "Usage: gmail-attachment-manager restart <CTID>"; exit 1; }; exec pct exec "$ARG" -- systemctl restart gmail-attachment-manager;;
 *) echo "Commands: status, update, logs, restart"; exit 1;;
esac
EOF
chmod 755 /usr/local/bin/gmail-attachment-manager
echo
echo "Proxmox management command installed:"
echo "  gmail-attachment-manager status ${CTID:-<CTID>}"
echo "  gmail-attachment-manager update ${CTID:-<CTID>}"
echo "  gmail-attachment-manager logs ${CTID:-<CTID>}"
echo "  gmail-attachment-manager restart ${CTID:-<CTID>}"
