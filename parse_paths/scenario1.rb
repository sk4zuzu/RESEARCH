require_relative 'junk'

def parse_paths(snaps, rhost, path_filter = /^disk\./)
    script = [<<~EOS]
        set -e -o pipefail; shopt -qs failglob
    EOS

    script << '('
    snaps.each do |snap|
        script << "#{restic("ls '#{snap}'", 'no-lock' => nil, 'json' => nil)} | jq --slurp .;"
    end
    script << ') | jq --slurp .'

    rc = run_action 'parse_paths', script.join("\n"), rhost

    raise StandardError, rc.stderr if rc.code != 0

    items = JSON.parse rc.stdout

    disks_by_snap = items.map do |docs|
        k = docs.find {|i| i['struct_type']&.eql?('snapshot') }
               &.dig('short_id')
        v = docs.select {|i| i['type']&.eql?('file') }
                .select {|i| i['name']&.match?(path_filter) }
                .map    {|i| i['path'] }
        [k, v]
    end.to_h

    disks_by_index = items.flatten
                          .select   {|i| i['type']&.eql?('file') }
                          .select   {|i| i['name']&.match?(path_filter) }
                          .map      {|i| [i['name'].split('.'), i['path']] }
                          .group_by {|i| i[0][1] }
                          .to_h     {|k, v| [k, v.map {|i| i[1] }] }

    raise StandardError, 'Backup does not contain any disks' \
        if disks_by_snap.empty? || disks_by_index.empty?

    other_by_snap = items.map do |docs|
        k = docs.find {|i| i['struct_type']&.eql?('snapshot') }
               &.dig('short_id')
        v = docs.select {|i| i['type']&.eql?('file') }
                .select {|i| i['name']&.eql?('vm.xml') }
                .map    {|i| i['path'] }
        [k, v]
    end.to_h

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
