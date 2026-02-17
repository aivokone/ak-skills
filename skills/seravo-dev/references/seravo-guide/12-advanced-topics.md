## Advanced Topics

### Nginx and .htaccess

Seravo uses Nginx — `.htaccess` files have **no effect**. Many WordPress plugins
(Gravity Forms, WooCommerce, etc.) rely on `.htaccess` for directory protection,
but these rules are silently ignored on Seravo.

Always verify plugin upload directories are protected via `nginx/*.conf`:

```nginx
# /data/wordpress/nginx/upload-protection.conf
location ~* /uploads/gravity_forms/ { deny all; }
location ~* /uploads/woocommerce_uploads/ { deny all; }
```

Custom Nginx rules go in `nginx/*.conf` — Seravo loads them into the server block
automatically and applies changes on `git push`.

When installing or auditing any plugin that mentions `.htaccess` in its docs,
check whether it creates directory protection rules and replicate them in Nginx.

### Custom Nginx Configuration on Seravo

Place files in `/data/wordpress/nginx/*.conf`.

Example:

```nginx
# /data/wordpress/nginx/security-headers.conf
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
```

Validate:

```bash
nginx -t
```

### DDEV Uploads Proxy Pattern

When uploads are too large to sync locally, proxy missing files to production:

```nginx
# .ddev/nginx_full/uploads-proxy.conf
location ~* /wp-content/uploads/ {
    try_files $uri @production;
}
location @production {
    proxy_pass https://PRODUCTION-URL;
}
```

Use this as default recommendation, but always ask user before applying uploads
strategy.

### Composer Dependency Management

For older Seravo template snapshots, run compatibility migration before normal
workflow:

- `johnpbloch/wordpress-core-installer`: `^2.0`
- `johnpbloch/wordpress-core`: `^5.0 || ^6.0`
- `composer/installers`: `^1.0 || ^2.0`
- `vlucas/phpdotenv`: `^2.4 || ^5.0`

Then:

```bash
composer update --no-interaction
```

### Dotenv and `wp-config.php` Compatibility

Use modern Dotenv API:

```php
$dotenv = Dotenv\Dotenv::createMutable($root_dir);
$dotenv->load();
```

And guard DB constants so DDEV-provided values can take precedence:

```php
if (!defined('DB_NAME')) { define('DB_NAME', getenv('DB_NAME')); }
if (!defined('DB_USER')) { define('DB_USER', getenv('DB_USER')); }
if (!defined('DB_PASSWORD')) { define('DB_PASSWORD', getenv('DB_PASSWORD')); }
if (!defined('DB_HOST')) { define('DB_HOST', getenv('DB_HOST')); }
```

### Environment-Specific Code

```php
if ('production' === getenv('WP_ENV')) {
    define('WP_DEBUG', false);
} elseif ('development' === getenv('WP_ENV')) {
    define('WP_DEBUG', true);
    define('WP_DEBUG_LOG', true);
}
```

### Shadow Environment Management

Use shadow for risk reduction before production changes:

```bash
ssh user@example.seravo.com -p 23456
wp-backup
wp-list-env | grep WP_ENV
```

For local testing with shadow data, export from shadow host and import to DDEV
using the same SSH stream pattern as production.

### WordPress Network Development

Useful commands:

```bash
wp site list
wp super-admin list
wp plugin list --url=https://example.com/subsite
wp user list --network
```

Local DDEV multisite tasks still require explicit path in Seravo layout:

```bash
ddev wp option get siteurl --url=https://subsite.example --path=/var/www/html/htdocs/wordpress
```

### Local Redis Strategy

If local Redis is not intentionally configured, keep Seravo object-cache drop-in
disabled (`object-cache.php.seravo-bak`) to prevent runtime and CLI failures.
