#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
set -x

apk --no-cache add \
    libvirt-daemon \
    qemu-img qemu-system-x86_64 qemu-modules

awk -i inplace -f- /etc/libvirt/qemu.conf <<'EOF'
/^#*user[^=]*=/            { $0 = "user=\"root\"" }
/^#*group[^=]*=/           { $0 = "group=\"root\"" }
/^#*security_driver[^=]*=/ { $0 = "security_driver=\"none\"" }
{ print }
EOF

awk -i inplace -f- /etc/libvirt/libvirtd.conf <<'EOF'
/^#*listen_tls[^=]*=/  { $0 = "listen_tls=0" }
/^#*listen_tcp[^=]*=/  { $0 = "listen_tcp=1" }
/^#*listen_addr[^=]*=/ { $0 = "listen_addr=\"0.0.0.0\"" }
/^#*auth_tcp[^=]*=/    { $0 = "auth_tcp=\"none\"" }
{ print }
EOF

awk -i inplace -f- /etc/conf.d/libvirtd <<'EOF'
/^#*LIBVIRTD_OPTS[^=]*=/ { $0 = "LIBVIRTD_OPTS=\"--listen\"" }
{ print }
EOF

rc-update add libvirtd

sync
