# GmailAttachmentManager Installer

Public bootstrap installer for the private GmailAttachmentManager application.

Run this as **root on the Proxmox VE host**:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuffysan/GmailAttachmentManager-Installer/main/install.sh)"
```

The installer asks for a fine-grained GitHub token that has read access to the private `tuffysan/GmailAttachmentManager` repository. It then creates the complete LXC and installs host-side management commands.

After installation:

```bash
gmail-attachment-manager status
gmail-attachment-manager update
gmail-attachment-manager logs
gmail-attachment-manager restart
```

If more than one Gmail Attachment Manager LXC exists, append its CTID.
