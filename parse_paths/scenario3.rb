require_relative 'junk'

def parse_paths(snaps, rhost, disk_filter = /\/disk\.\d+\.\d+$/)
    script = [<<~EOS]
        set -e -o pipefail; shopt -qs failglob
    EOS

    snaps_quoted = snaps.map {|s| "'#{s}'" }

    script << restic("snapshots #{snaps_quoted.join(' ')}", 'no-lock' => nil,
                                                            'json'    => nil)

    rc = run_action 'parse_paths', script.join("\n"), rhost

    raise StandardError, rc.stderr if rc.code != 0

    items = JSON.parse rc.stdout

    disks_by_snap = {}
    other_by_snap = {}
    items.each do |item|
        snap = item['short_id']
        item['paths'].each do |path|
            if path.match?(disk_filter)
                (disks_by_snap[snap] ||= []) << path
            else
                (other_by_snap[snap] ||= []) << path
            end
        end
    end

    disks_by_index = {}
    disks_by_snap.values.flatten.each do |path|
        name   = Pathname.new(path).basename.to_s
        tokens = name.split('.')
        (disks_by_index[tokens[1]] ||= []) << path
    end

    raise StandardError, 'Backup does not contain any disks' \
        if disks_by_snap.empty? || disks_by_index.empty?

    {
        :disks => {
            :by_snap  => disks_by_snap,
            :by_index => disks_by_index,
            :uniq     => disks_by_index.values.flatten.uniq
        },
        :other => {
            :by_snap => other_by_snap,
            :uniq    => other_by_snap.values.flatten.uniq
        }
    }
end

if caller.empty?
    paths = parse_paths(get_snaps, nil)
    STDOUT.puts JSON.pretty_generate(paths)
end
