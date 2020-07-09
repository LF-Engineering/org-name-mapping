#!/usr/bin/env ruby

require 'csv'
require 'yaml'
require './mgetc'
require 'pry'

def convert(csvfn, ymlfn, outfn)
  data = YAML.load_file(ymlfn)
  existing = {}
  data['mappings'].each do |row|
    existing[row[1]] = row[0]
    #existing[row[1]] = row[0].gsub('\\\\', '\\')
  end
  map = {}
  CSV.foreach(csvfn, headers: true) do |row|
    h = row.to_h
    n = h['SFDC NAME']
    next if n.nil? || n == ''
    c = h['Calculated']
    next if c == 'FALSE'
    dn = h['DA Name']
    map[n] = [] unless map.key?(n)
    map[n] << dn
  end
  unknowns = {}
  lines = {}
  map.each do |n, names|
    names = names.sort.uniq
    re = '^[[:space:]]*'
    l = names.length
    re += '(' if l > 1
    names.each_with_index do |name, i|
      name.each_char do |r|
          if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r.ord > 0x80
          re += r
        elsif r >= 'A' && r <= 'Z'
          re += r.downcase
        elsif ['!', '/', ',', '-', '&', ']', '~', "'", '"'].include?(r)
          re += r + '?'
        elsif [' ', "\t"].include?(r)
          re += '[[:space:]]*'
        elsif ['|', '(', ')', '.', '*', '['].include?(r)
          re += '\\\\' + r + '?'
        else
          unknowns[r] = 0 unless unknowns.key?(r)
          unknowns[r] += 1
        end
      end
      re += '|' if i < l-1
    end
    re += ')' if l > 1
    re += '[[:space:]]*$'
    if existing.key?(n)
      if existing[n] == re
        puts "Exact mapping already present in YAML: " + re
      else
        puts "Collision for " + n + ", choose:"
        puts "(E)xisting: " + existing[n]
        puts "(N)ew:      " + re
        print "> "
        answer = mgetc.downcase
        puts ''
        return if answer == 'q'
        re = existing[n] if answer == 'e'
      end
    end
    lines[n] = "  - ['" + re + "', '" + n + "']"
  end
  existing.each do |n, re|
    unless map.key?(n)
      lines[n] = "  - ['" + re + "', '" + n + "']"
    end
  end
  binding.pry if unknowns.length > 0
  File.open(outfn, "w") do |f|
    f.puts("---")
    f.puts("mappings:")
    lines.keys.sort.each { |key| f.puts(lines[key]) }
  end
end

if ARGV.size < 3
  puts "Missing arguments: export.csv mapping.yaml new_mapping.yaml"
  exit(1)
end

convert(ARGV[0], ARGV[1], ARGV[2])
