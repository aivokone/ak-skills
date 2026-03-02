# SwiftBar Plugin Debug Analysis: status.sh

## Problem

The plugin displays nothing in the macOS menu bar.

## Root Causes Found

### 1. Invalid shebang line (critical)

**Original:** `#/bin/bash`
**Fixed:** `#!/bin/bash`

The shebang is missing the `!` character. A valid shebang must start with `#!`. Without it, the operating system does not recognize the file as a bash script. SwiftBar uses the shebang to determine the interpreter for the plugin. With an invalid shebang, the script either fails to execute or is interpreted incorrectly, producing no usable output.

### 2. Unquoted pipe character causes shell piping (critical)

**Original:** `echo Click here | href=https://google.com`
**Fixed:** `echo "Click here | href=https://google.com"`

The `|` character is a shell pipe operator. Without quotes, bash interprets this line as two commands connected by a pipe:

1. `echo Click here` — outputs "Click here" to stdout
2. `href=https://google.com` — bash tries to run this as a command, which fails

The result is that `href=https://google.com` is not a valid command, so the pipeline produces an error on stderr (which SwiftBar ignores) and no output on stdout for this line. More importantly, depending on how the shell handles the overall script execution with the broken shebang, this error can cascade and suppress all output.

The fix is to quote echo arguments so the `|` character is treated as a literal character in the string, which is what SwiftBar's output protocol expects.

## Corrected Plugin

```bash
#!/bin/bash
echo "Status: OK"
echo "---"
echo "Details"
echo "Click here | href=https://google.com"
```

## Additional Recommendations

- **Quote all echo arguments** as a habit. This prevents unexpected shell interpretation of special characters (`|`, `>`, `$`, etc.) in SwiftBar output lines.
- **Make the file executable** before placing it in the SwiftBar Plugin Folder: `chmod +x status.sh`
- **Add a refresh interval to the filename** (e.g., `status.5m.sh`) so SwiftBar auto-refreshes the plugin periodically.
- **Test in terminal first**: run `./status.sh` directly to verify the output matches the expected SwiftBar protocol format before relying on SwiftBar to pick it up.
