#!/usr/bin/env ruby

require "#{File.expand_path(File.dirname(__FILE__))}/bashr_core.rb"


puts Bashr.generate_atom(Time.now.utc.xmlschema, Bashr.fetch_entries)
