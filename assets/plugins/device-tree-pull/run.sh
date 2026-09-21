#!/bin/sh
# This package is intentionally executed by NeoXTerm's native hardware collector.
# Keeping an entrypoint makes the package inspectable and consistent with every
# local NeoXTerm plugin, while the Rust implementation preserves SSH/ADB behavior
# and safe binary artifact recovery.

printf '%s\n' 'device-tree-pull must be run through NeoXTerm (nxt plugin run or NeoXTerm Desktop).' >&2
exit 2
