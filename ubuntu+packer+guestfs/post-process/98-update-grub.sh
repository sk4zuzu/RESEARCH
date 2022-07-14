#!/usr/bin/env bash

set -o errexit -o nounset
set -x

rm -rf /etc/default/grub.d/

gawk -i inplace -f- /etc/default/grub <<'EOF'
/^GRUB_CMDLINE_LINUX_DEFAULT=/ { found=1 }
/^GRUB_CMDLINE_LINUX_DEFAULT=/ { gsub(/\s*quiet\s*/, "") }
/^GRUB_CMDLINE_LINUX_DEFAULT=/ { gsub(/\s*splash\s*/, "") }
/^GRUB_CMDLINE_LINUX_DEFAULT=/ && !/net.ifnames=0/ { gsub(/"$/, " net.ifnames=0\"") }
/^GRUB_CMDLINE_LINUX_DEFAULT=/ && !/biosdevname=0/ { gsub(/"$/, " biosdevname=0\"") }
{ print }
END { if (!found) print "GRUB_CMDLINE_LINUX_DEFAULT=\" net.ifnames=0 biosdevname=0\"" >> FILENAME }
EOF

gawk -i inplace -f- /etc/default/grub <<'EOF'
BEGIN { update = "GRUB_TIMEOUT=0" }
/^GRUB_TIMEOUT=/ { $0 = update; found=1 }
{ print }
END { if (!found) print update >> FILENAME }
EOF

update-grub2

sync
