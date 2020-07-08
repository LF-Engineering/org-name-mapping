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
  map.each do |n, names|
    names = names.sort.uniq
    re = '^[[:space:]]*'
    l = names.length
    re += '(' if l > 1
    names.each_with_index do |name, i|
      re += '|' if i < l-1
    end
    re += ')' if l > 1
    re += '[[:space:]]*$'
    puts re
    binding.pry if l > 2
  end
end

if ARGV.size < 1
  puts "Missing arguments: export.csv"
  exit(1)
end

convert(ARGV[0])
