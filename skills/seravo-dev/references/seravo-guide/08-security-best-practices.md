## Security Best Practices

### SSH Key Management

**Always use SSH keys** (not passwords):
```bash
# Generate strong key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Or RSA 4096-bit
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Add Seravo host profile (force IPv4)
cat >> ~/.ssh/config <<'EOF'
Host mysite
    HostName example.seravo.com
    Port 12345
    User example
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddressFamily inet
EOF

# Add host key before first login
ssh-keyscan -4 -p 12345 example.seravo.com >> ~/.ssh/known_hosts

# Add key to Seravo
ssh-copy-id -o AddressFamily=inet -p 12345 user@example.seravo.com

# Verify
ssh -4 -p 12345 user@example.seravo.com 'echo OK'
```

Seravo note:
- DNS may return IPv6 and IPv4, but SSH port may only accept IPv4.
- Prefer `AddressFamily inet` and `-4` for `ssh` / `ssh-keyscan`.

For non-interactive terminals (agent/CI), use `sshpass` when password bootstrap is required:
```bash
if ! command -v sshpass >/dev/null; then
  if command -v brew >/dev/null; then
    brew install hudochenkov/sshpass/sshpass
  elif command -v apt-get >/dev/null; then
    sudo apt-get update && sudo apt-get install -y sshpass
  fi
fi

SSHPASS='YOUR_PASSWORD' sshpass -e ssh-copy-id -o AddressFamily=inet -p 12345 user@example.seravo.com
```

> **Agent note**: `sshpass` is a one-time SSH key bootstrap — once `ssh-copy-id` succeeds,
> key-based auth replaces password auth entirely. Never store passwords in scripts or
> reuse `SSHPASS` beyond this step. Always ask for user confirmation before running
> `sudo` commands. The `hudochenkov/sshpass` Homebrew tap is required because
> `sshpass` was intentionally removed from the main Homebrew repository.

**Multiple developers**:
- Each developer adds their own public key to `~/.ssh/authorized_keys`
- Don't share private keys
- Audit keys regularly: `cat ~/.ssh/authorized_keys`

### Credential Management

**Never hardcode credentials**:
- wp-config.php uses getenv() for all secrets
- View with: `wp-list-env`
- Override locally with .env (gitignored)

**Password reset workflow**:
```bash
# Check for breaches first
wp-check-haveibeenpwned <hash>

# Reset if compromised
wp-reset-all-passwords

# Or reset SSH password
wp-reset-ssh-password
```

### Access Auditing

**Monitor logins**:
```bash
# SSH access attempts
wp-last-ssh-logins

# WordPress logins
wp-last-wp-logins

# File changes
wp-backup-list-changes
```

**Suspicious activity response**:
```bash
# 1. Review changes
wp-backup-list-changes

# 2. Restore from backup if needed
# (Coordinate with Seravo support)

# 3. Reset all sessions
wp-reset-all-sessions

# 4. Change passwords
wp-reset-all-passwords

# 5. Audit users
wp user list --role=administrator
```

### Database Security

**No direct MySQL access from external networks**:
- Only via SSH tunnel
- Use wp db cli for shell access
- Get credentials: `wp-list-env | grep DB_`

**For external tools** (Sequel Pro, TablePlus):
```bash
# Set up SSH tunnel
ssh -L 3306:localhost:3306 -p 12345 user@example.seravo.com

# In another terminal, connect to localhost:3306
# Credentials from wp-list-env
```
