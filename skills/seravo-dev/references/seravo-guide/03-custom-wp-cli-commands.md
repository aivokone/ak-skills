## Custom WP-CLI Commands

Seravo provides custom commands prefixed with `wp-`. These are primarily useful on
Seravo servers (production/shadow). Local DDEV workflows should use standard
`wp db export` + SSH + rsync patterns.

### Backup and Restore

**wp-backup**
- Dumps database and backs up `/data` directory using rdiff-backup
- Runs automatically every night
- Run manually before high-risk changes

```bash
wp-backup
```

**wp-backup-status**
- Lists backup increments and sizes

```bash
wp-backup-status
```

**wp-backup-list-changes**
- Lists files changed since last backup

```bash
wp-backup-list-changes
```

**wp-backup-list-changes-since**

```bash
wp-backup-list-changes-since 2024-01-15
```

### Database Synchronization

**Recommended local sync model (DDEV-first):**
- Export from Seravo host with SSH stream
- Import with `ddev import-db`
- Run explicit URL replacement and cache flush with required `--path`

```bash
ssh -4 -p PORT USER@HOST 'wp db export -' | gzip > /tmp/production.sql.gz
ddev import-db --file=/tmp/production.sql.gz

ddev wp search-replace 'https://production-url' 'https://SLUG.ddev.site' \
  --all-tables --path=/var/www/html/htdocs/wordpress
ddev wp cache flush --path=/var/www/html/htdocs/wordpress
```

**Legacy local pull helpers (deprecated for primary guidance):**
- `wp-pull-production-db`
- `wp-pull-shadow-db` / `wp-pull-staging-db`
- `wp-pull-production-themes`
- `wp-pull-production-core`
- `wp-development-up`

These may exist in older templates but are not the default recommendation for
modern local workflows.

### Cache Management

**wp-purge-cache**
- Purges all major server-side caches:
  - Nginx proxy cache
  - WordPress object cache
  - WordPress rewrite cache
  - PageSpeed cache

```bash
wp-purge-cache
```

For local DDEV cache reset, prefer:

```bash
ddev wp cache flush --path=/var/www/html/htdocs/wordpress
```

### Security and Access

**wp-reset-ssh-password**
```bash
wp-reset-ssh-password
```

**wp-reset-all-passwords**
```bash
wp-reset-all-passwords
```

**wp-reset-all-sessions**
```bash
wp-reset-all-sessions
```

**wp-check-haveibeenpwned**
```bash
wp-check-haveibeenpwned <hash>
```

### Monitoring and Debugging

**wp-last-ssh-logins**
```bash
wp-last-ssh-logins
```

**wp-last-wp-logins**
```bash
wp-last-wp-logins
```

**wp-list-files-mtime** / **wp-list-files-ctime**
```bash
wp-list-files-mtime
wp-list-files-ctime
```

### Performance Testing

**wp-speed-test**
```bash
wp-speed-test
```

**wp-load-test**
```bash
wp-load-test
```

### WordPress Network (Multisite)

**wp-network-status**
```bash
wp-network-status
```

For multisite operations, many commands need `--url=` or `--network`.

### WP-Cron on Production

`wp cron event run <hook>` modifies state — the agent must **not** run it on
production. Instead, tell the user what to run and why.

Seravo has system cron that runs `wp-cron.php` regularly, so daily scheduled
tasks (like Gravity Forms entry retention cleanup) will execute automatically.
Manual triggering is only needed for immediate execution.

Listing cron events is safe (read-only):

```bash
wp cron event list
```

Running a cron event is a write operation (agent must provide command for user):

```bash
# User runs this on production:
wp cron event run <hook_name>
```

### Internal/Automated Commands (Legacy)

These may be present in old templates and should not be primary local guidance:
- `wp-vagrant-activation`
- `wp-vagrant-dump-db`
- `wp-vagrant-import-db`
- `wp-activate-git-hooks`
- `wp-generate-ssl`
- `wp-activate-asset-proxy`

### Plugin Management

**wp-seravo-plugin-update**
```bash
wp-seravo-plugin-update
wp-seravo-plugin-update --dev
```

### Environment Variables

**wp-list-env**
```bash
wp-list-env
```

Useful keys include `WP_ENV`, DB variables, and runtime service metadata.
