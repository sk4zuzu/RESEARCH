#!/usr/bin/env ruby

# frozen_take_exact_literal: true

class ParserEngine
    class ParseFailure < StandardError; end

    def initialize(input)
        @input = input
        @pos   = 0
    end

    def zero_or_more(parser)
        matches = []
        loop { matches << backtrack { parser.call } }
    rescue ParseFailure
        matches
    end

    def one_of(*parsers)
        parsers.each do |parser|
            return backtrack { parser.call }
        rescue ParseFailure
            next
        end
        raise ParseFailure
    end

    def between(open, close, inner)
        backtrack { open.call; inner.call.tap { close.call } }
    end

    def sep_at(separator, parser)
        matches = []
        backtrack {
            p = parser.call
            matches << p
            nil
        }
        loop {
            backtrack {
                s = separator.call
                p = parser.call
                matches << s
                matches << p
                nil
            }
        }
    rescue ParseFailure
        matches
    end

    def peek(len = 1)
        ((s = input.byteslice(0, len)).length == len) ? s : (raise ParseFailure)
    end

    def take(len = 1)
        peek(len).tap { consume(len) }
    end

    def take_exact(pat)
        backtrack { ((s = take(pat.length)) == pat) ? s : (raise ParseFailure) }
    end

    def take_while(pred)
        s = +''
        loop { s << backtrack { pred.call(c = take) ? c : (raise ParseFailure) } }
        s
    rescue ParseFailure
        s
    end

    def fail_parse
        raise ParseFailure
    end

    private

    def input
        @input.byteslice(@pos..(-1))
    end

    def consume(len = 1)
        @pos += len
    end

    def backtrack
        pos_before = @pos
        yield
    rescue ParseFailure
        @pos = pos_before
        raise
    end
end

class OneParser < ParserEngine
    PARSE = proc {
        attribute = proc { take_while proc { |c| c[/[[:alnum:]_]/] } }

        quoted = proc {
            between proc { take_exact %[\"] },
                    proc { take_exact %[\"] }, proc {
                escaped = false
                %[\"] + (take_while proc { |c|
                    (c == %[\\] || (c == %[\"] && escaped)) \
                        ? (escaped = !escaped; true)
                        : (c != %[\"])
                }) + %[\"]
            }
        }

        unquoted = proc {
            peek[/[^\]\[",#[:space:]]/] \
                ? (take_while proc { |c| c[/[^\]\[",#[:space:]]/] })
                : fail_parse
        }

        space = proc { take_while proc { |c| c[/[[:space:]]/] } }

        comment = proc {
            (zero_or_more proc {
                space.call + (take_exact %[\#]) + (take_while proc { |c| c != %[\n] })
            }).join
        }

        blank = proc { take_while proc { |c| c[/[[:blank:]]/] } }

        pair = proc {
            [ blank.call,
              attribute.call,
              blank.call + (take_exact %[\=]) + blank.call,
              (one_of quoted, unquoted),
              comment.call ]
        }

        item = proc {
            [ comment.call + space.call,
              attribute.call,
              blank.call + (take_exact %[\=]) + blank.call,
              (one_of quoted, unquoted),
              blank.call ]
        }

        vector = proc {
            [ blank.call,
              attribute.call,
              blank.call + (take_exact %[\=]) + blank.call,
              (between proc { take_exact %[\[] },
                       proc { take_exact %[\]] },
                       proc { [ %[\[] + space.call,
                                *(sep_at proc { take_exact %[\,] }, item),
                                comment.call,
                                space.call + %[\]] ] }),
              blank.call + comment.call ]
        }

        sep_at proc { take_exact %[\n] },
               proc { one_of pair, vector, comment }
    }

    def parse
        @parsed = instance_eval &PARSE
    end

    def render
        (recurse = proc { |node|
            case
            when node.is_a?(String)
                node
            when node.is_a?(Array)
                node.each_with_object(+'') { |vv, acc| acc << (recurse.call vv) }
            else
                raise StandardError, 'invalid structure'
            end
        }).call @parsed
    end

    def match(path)
        atrb, atrb_i, item, item_i = ypath(path)
        (recurse = proc { |node, pfx = '', acc = []|
            case
            when node.is_a?(String)
                acc << pfx
            when node.is_a?(Hash)
                pfx += '/' unless pfx.empty?
                node.each { |k, vv| recurse.call vv, (pfx + k), acc }
            when node.is_a?(Array)
                if node.count == 1
                    recurse.call node[0], pfx, acc
                else
                    node.each_with_index { |vv, i| recurse.call vv, (pfx + "[#{i+1}]"), acc }
                end
            end
            acc
        }).call (filtered patterns: [atrb, item], indices: [atrb_i, item_i])
    end

    def get(path)
        atrb, atrb_i, item, item_i = ypath(path)
        (recurse = proc { |node, acc = []|
            case
            when node.is_a?(String)
                acc << node
            when node.is_a?(Hash)
                node.each { |_, vv| recurse.call vv, acc }
            when node.is_a?(Array)
                node.each { |vv| recurse.call vv, acc }
            end
            acc
        }).call (filtered patterns: [atrb, item], indices: [atrb_i, item_i])
    end

    private

    def ypath(path)
        regex = %r{ ^
                    ( [[:alnum:]_*]+ )
                    (?:
                        \[ ( [[:digit:]]* ) \]
                    )?
                    (?:
                        /
                        ( [[:alnum:]_*]+ )
                        (?:
                            \[ ( [[:digit:]]* ) \]
                        )?
                    )?
                    $ }x
        raise StandardError, 'invalid ypath' if (m = regex.match(path)).nil?

        atrb   = m[1]
        atrb_i = m[2].to_s.empty? ? nil : m[2].to_i
        item   = m[3]
        item_i = m[4].to_s.empty? ? nil : m[4].to_i
        raise StandardError, 'invalid ypath' if atrb.nil? \
                                             || (item.nil? && !item_i.nil?) \
                                             || (!atrb_i.nil? && atrb_i.to_i < 1) \
                                             || (!item_i.nil? && item_i.to_i < 1)

        [atrb, atrb_i, item, item_i]
    end

    def simplified(node = @parsed)
        (recurse = proc { |node|
            node.each_with_object({}) do |n, acc|
                next unless n.is_a?(Array)
                case
                when n[3].is_a?(String)
                    (acc[n[1]] ||= []) << n[3]
                when n[3].is_a?(Array)
                    (acc[n[1]] ||= []) << (recurse.call n[3])
                end
            end
        }).call node
    end

    def filtered(node = @parsed, patterns: [], indices: [])
        (recurse = proc { |node, patterns, indices|
            case
            when node.is_a?(String)
                node if patterns.empty?
            when node.is_a?(Hash)
                unless (pat = patterns.shift).nil?
                    node.each_with_object({}) do |(k, vv), acc|
                        if File.fnmatch?(pat, k)
                            v = recurse.call vv, patterns.dup, indices.dup
                            acc[k] = v unless v.nil?
                        end
                    end.then do |acc|
                        acc unless acc.empty?
                    end
                end
            when node.is_a?(Array)
                unless (idx = indices.shift).nil?
                    unless (vv = node[idx-1]).nil?
                        v = recurse.call vv, patterns.dup, indices.dup
                        [v] unless v.nil?
                    end
                else
                    node.each_with_object([]) do |vv, acc|
                        v = recurse.call vv, patterns.dup, indices.dup
                        acc << v unless v.nil?
                    end.compact.then do |acc|
                        acc unless acc.empty?
                    end
                end
            end
        }).call (simplified node), patterns.compact, indices
    end

end
