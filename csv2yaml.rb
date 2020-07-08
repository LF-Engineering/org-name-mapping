#!/usr/bin/env ruby

require 'csv'
require 'pry'

def convert(fn)
  map = {}
  CSV.foreach(fn, headers: true) do |row|
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
        elsif ['|', '(', '.', '*', '['].include?(r)
          re += '\\' + r + '?'
        else
          unknowns[r] = 0 unless unknowns.key?(r)
          unknowns[r] += 1
        end
      end
      re += '|' if i < l-1
    end
    re += ')' if l > 1
    re += '[[:space:]]*$'
    puts "  ['" + re + "'], '" + n + "']"
  end
  binding.pry if unknowns.length > 0
end

if ARGV.size < 1
  puts "Missing arguments: export.csv"
  exit(1)
end

convert(ARGV[0])
