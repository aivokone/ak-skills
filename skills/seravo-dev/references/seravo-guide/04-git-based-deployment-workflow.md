## Git-Based Deployment Workflow

Seravo uses Git for code deployment. Every site has a Git remote named 'production'.

### Initial Setup
```bash
# Clone your site (if not already)
git clone ssh://$USER@$SITE.seravo.com:[$PORT]/data/wordpress ~/Projects/$SITE --origin production

# OR initialize in existing directory
cd /data/wordpress
git init
git remote add production ssh://$USER@$SITE.seravo.com:[$PORT]/data/wordpress
```

### First Push to Production

Seravo repos default to `master` branch. If your local/GitHub repo uses `main`:

- `git push production main` creates a **new** `main` branch — the site stays on `master`
- Use `git push production main:master` to push to the active branch

Check production branch before pushing:

```bash
ssh -4 -p PORT USER@HOST "cd /data/wordpress && git rev-parse --abbrev-ref HEAD"
```

### Untracked File Conflicts on First Push

Seravo's initial repo may not track the theme or `wp-content` files. When pushing
a repo that tracks these, `receive.denyCurrentBranch=updateInstead` refuses if
untracked files on the server conflict with incoming tracked files.

Error: `Untracked working tree file 'X' would be overwritten by merge`

Resolution (the **user** must do this on production, not the agent):

1. SSH to production
2. `git stash` for modified tracked files
3. For untracked conflicts: `git add <conflicting files> && git stash`
4. Exit SSH, then push from local: `ALLOW_PRODUCTION=1 git push production main:master`

### Production Push Safeguard

Recommended: add a pre-push hook that blocks pushes to the `production` remote
unless explicitly overridden:

```bash
# scripts/git-hooks/pre-push
# Checks $REMOTE == "production" and requires ALLOW_PRODUCTION=1 env variable
```

Install:

```bash
cd .git/hooks && ln -s ../../scripts/git-hooks/pre-push .
```

Claude Code deny rules complement this:

```
"Bash(*push production*)"
"Bash(*ALLOW_PRODUCTION*)"
```

These deny rules ensure the agent never pushes to production directly —
the user must run the push command themselves.

### PHP Version Sync

Seravo may update PHP version on the server independently. The version is set
in `nginx/php.conf` (e.g., `set $mode php8.4;`). Before first push, check production:

```bash
ssh -4 -p PORT USER@HOST "cat /data/wordpress/nginx/php.conf"
```

Update local repo to match — otherwise a push may downgrade PHP on the server.

### Standard Workflow
```bash
# Make changes locally
vim wp-content/themes/mytheme/functions.php

# Commit changes
git add .
git commit -m "Add custom functionality"

# Git hooks run tests automatically (if configured)
# Tests run on commit

# Push to production
git push production master
# Output shows:
# - Object count
# - Tests run (if configured)
# - Deployment status
```

### Git Hooks

**wp-activate-git-hooks** sets up automated testing on every commit:
- Pre-commit: PHP lint, syntax checking
- Pre-push: Can run integration tests
- Configuration in `.git/hooks/`

**Best practices**:
1. Always commit with meaningful messages
2. Test locally in DDEV before pushing
3. Review git hooks output for test failures
4. Keep commits atomic and focused
5. Use branches for experimental features

### SSH Configuration

Add to `~/.ssh/config` for easier access:
```
Host mysite
    HostName example.seravo.com
    Port 12345
    User example
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddressFamily inet
```

Prime host key once (IPv4-safe for Seravo):
```bash
ssh-keyscan -4 -p 12345 example.seravo.com >> ~/.ssh/known_hosts
```

Then simply: `ssh mysite`
