require 'csv'
require 'highline'
require 'inflecto'
require 'json'
require 'paint'
require 'pp'
require 'terminal-table'
require 'whirly'
require 'yaml'

module MrMurano
  module Verbose
    def verbose(msg)
      if $cfg['tool.verbose'] then
        say msg
      end
    end

    def debug(msg)
      if $cfg['tool.debug'] then
        say msg
      end
    end

    def warning(msg)
      $stderr.puts HighLine.color(msg, :yellow)
    end

    def error(msg)
      $stderr.puts HighLine.color(msg, :red)
    end

    ## Output tabular data
    # +data+:: Data to write. Preferably a Hash with :headers and :rows
    # +ios+:: Output stream to write to, if nil, then use $stdout
    # Output is either a nice visual table or CSV.
    def tabularize(data, ios=nil)
      fmt = $cfg['tool.outformat']
      ios = $stdout if ios.nil?
      cols = nil
      rows = nil
      title = nil
      if data.kind_of?(Hash) then
        cols = data[:headers] if data.has_key?(:headers)
        rows = data[:rows] if data.has_key?(:rows)
        title = data[:title]
      elsif data.kind_of?(Array) then
        rows = data
      elsif data.respond_to?(:to_a) then
        rows = data.to_a
      elsif data.respond_to?(:each) then
        rows = []
        data.each{|i| rows << i}
      else
        error "Don't know how to tabularize data."
        return
      end
      if fmt =~ /csv/i then
        cols = [] if cols.nil?
        rows = [[]] if rows.nil?
        CSV(ios, :headers=>cols, :write_headers=>(not cols.empty?)) do |csv|
          rows.each{|v| csv << v}
        end
      else
        # table.
        table = Terminal::Table.new
        table.title = title unless title.nil?
        table.headings = cols unless cols.nil?
        table.rows = rows unless rows.nil?
        ios.puts table
      end
    end

    ## Format and print the object
    # Handles many of the raw 'unpolished' formats.
    def outf(obj, ios=nil, &block)
      fmt = $cfg['tool.outformat']
      ios = $stdout if ios.nil?
      case fmt
      when /yaml/i
        ios.puts Hash.transform_keys_to_strings(obj).to_yaml
      when /pp/
        pp obj
      when /json/i
        ios.puts obj.to_json
      else # aka best.
        # sometime ‘best’ is only know by the caller, so block.
        if block_given? then
          yield obj, ios
        else
          if obj.kind_of?(Array) then
            obj.each {|i| ios.puts i.to_s}
          else
            ios.puts obj.to_s
          end
        end
      end
    end

    EXO_QUADRANTS = [
      "▚",
      "▘",
      "▝",
      "▞",
      "▖",
      "▗",
    ]
    def self.whirly_start(msg)
      unless $cfg['tool.no-progress']
        self.whirly_stop
        Whirly.start spinner: MrMurano::Verbose::EXO_QUADRANTS,
          status: msg, append_newline: false
        @@whirly_time = Time.now
        @@whirly_cols, _ = HighLine::SystemExtensions.terminal_size
      end
    end

    def whirly_start(msg)
      MrMurano::Verbose::whirly_start(msg)
    end

    def self.whirly_stop
      unless $cfg['tool.no-progress'] or !defined?(@@whirly_time)
        self.whirly_linger
        Whirly.stop
        # The progress indicator is always overwritten.
        if @@whirly_cols
          $stdout.print (" " * @@whirly_cols) + "\r"
          $stdout.flush
        end
      end
    end

    def whirly_stop
      MrMurano::Verbose::whirly_stop
    end

    def self.whirly_linger
      unless $cfg['tool.no-progress'] or !defined?(@@whirly_time)
        not_so_fast = 0.55 - (Time.now - @@whirly_time)
        if not_so_fast > 0
          sleep not_so_fast
        end
      end
    end

    def self.whirly_msg(msg)
      unless $cfg['tool.no-progress'] or !defined?(@@whirly_time)
        self.whirly_linger
        Whirly.configure status: msg
      end
    end

    def whirly_msg(msg)
      MrMurano::Verbose::whirly_msg msg
    end

    def self.ask_yes_no(question, default)
      confirm = ask("Really delete all solutions? [Y/n] ")
      if default
        answer = ["", "y", "ye", "yes"].include?(confirm.downcase)
      else
        answer = !["", "n", "no"].include?(confirm.downcase)
      end
      answer
    end

    def self.pluralize?(word, count)
      unless count == 1
        return Inflecto.pluralize(word)
      end
      word
    end

    def pluralize?(word, count)
      MrMurano::Verbose::pluralize?(word, count)
    end

  end
end

module MrMurano
  class Blather
    include Verbose
    #def initialize()
    #end
  end
end

#  vim: set ai et sw=2 ts=2 :
