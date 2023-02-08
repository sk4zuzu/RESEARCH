#!/usr/bin/env bash

: "${VT_NAME:=alpine317}"
: "${VM_NAME:=asd}"
: "${DS_NAME:=restic}"

set -o errexit -o nounset -o pipefail

wait_for_vm() (
    local retry
    for retry in 9 8 7 6 5 4 3 2 1 0; do
        if onevm show "$VM_NAME" -j | jq -re '.VM.LCM_STATE == "3"'; then break; fi
        sleep 4
    done && [[ "$retry" -gt 0 ]]
)

wait_for_image() {
    local image_id=$(onevm show "$VM_NAME" -j | jq -r '.VM.BACKUPS.BACKUP_IDS.ID')
    local retry
    echo "IMAGE ID: $image_id"
    for retry in 9 8 7 6 5 4 3 2 1 0; do
        if oneimage show "$image_id" -j | jq -re '.IMAGE.STATE == "1"'; then break; fi
        sleep 4
    done && [[ "$retry" -gt 0 ]]
}

(export EDITOR="gawk -i inplace '$(cat)'" && onedatastore update -a "$DS_NAME") <<'EOF'
BEGIN {
  update1 = "RESTIC_PRUNE_MAX_REPACK=\"4G\"";
  update2 = "RESTIC_PRUNE_MAX_UNUSED=\"1%\"";
}
{ print }
ENDFILE {
  print update1;
  print update2;
}
EOF

onevm show "$VM_NAME" || onetemplate instantiate "$VT_NAME" --name "$VM_NAME"

wait_for_vm

(export EDITOR="gawk -i inplace '$(cat)'" && onevm updateconf -a "$VM_NAME") <<'EOF'
BEGIN {
  update1 = "FS_FREEZE=\"NONE\"";
  update2 = "KEEP_LAST=\"4\"";
  update3 = "MODE=\"INCREMENT\"";
}
/^BACKUP_CONFIG\s*=/ { $0 = "BACKUP_CONFIG=[" update1 "," update2 "," update3 "," }
{ print }
EOF

for RETRY in f e d c b a 9 8 7 6 5 4 3 2 1 0; do

wait_for_vm

(export EDITOR="gawk -i inplace '$(cat)'" && onevm updateconf -a "$VM_NAME") <<EOF
BEGIN {
  update1 = "START_SCRIPT=\\"(dd if=/dev/urandom bs=1024 count=8192 >> /asd; echo $RETRY > /RETRY) && sync\\""
}
/^CONTEXT\s*=/ { \$0 = "CONTEXT=[" update1 "," }
{ print }
EOF

wait_for_vm

onevm backup "$VM_NAME" -d "$DS_NAME"

wait_for_vm

wait_for_image

done

restic snapshots --no-lock --json | jq -r '.[].short_id' | while read SNAP; do
    DISK=$(restic ls "$SNAP" --no-lock --json 2>/dev/null | jq -r 'select(has("name")) | select(.name | startswith("disk.")).path')
    restic dump "$SNAP" "$DISK" > "$(basename "$DISK").qcow2"
done

restic snapshots --no-lock --json | jq -r '.[].short_id' | while read SNAP; do
    SIZE=$(restic stats "$SNAP" --no-lock --json 2>/dev/null | jq -r '.total_size/(1024*1024)')
    echo "$SNAP: $SIZE"
done
