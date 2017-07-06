# Last Modified: 2017.07.05 /coding: utf-8
# frozen_string_literal: true

# Copyright © 2016-2017 Exosite LLC.
# License: MIT. See LICENSE.txt.
#  vim:tw=0:ts=2:sw=2:et:ai

require 'csv'
require 'highline'
require 'inflecto'
require 'json'
require 'paint'
require 'pp'
require 'terminal-table'
require 'whirly'
require 'yaml'
require 'MrMurano/progress'

module MrMurano
  # Verbose is a mixin for various terminal output features.
  module Verbose
    def verbose(msg)
      say msg if $cfg['tool.verbose']
    end

    def debug(msg)
      say msg if $cfg['tool.debug']
    end

    def warning(msg)
      MrMurano::Verbose.warning(msg)
    end

    def self.warning(msg)
      $stderr.puts HighLine.color(msg, :yellow)
    end

    def error(msg)
      MrMurano::Verbose.error(msg)
    end

    def self.error(msg)
      # See also Commander::say_error
      $stderr.puts HighLine.color(msg, :red)
    end

    ## Output tabular data
    # +data+:: Data to write. Preferably a Hash with :headers and :rows
    # +ios+:: Output stream to write to, if nil, then use $stdout
    # Output is either a nice visual table or CSV.

    TABULARIZE_DATA_FORMAT_ERROR = 'Unexpected data format: do not know how to tabularize.'

    def tabularize(data, ios=nil)
      MrMurano::Verbose.tabularize(data, ios)
    end

    def self.tabularize(data, ios=nil)
      fmt = $cfg['tool.outformat']
      ios = $stdout if ios.nil?
      cols = nil
      rows = nil
      title = nil
      if data.is_a?(Hash)
        cols = data[:headers] if data.key?(:headers)
        rows = data[:rows] if data.key?(:rows)
        title = data[:title]
      elsif data.is_a?(Array)
        rows = data
      elsif data.respond_to?(:to_a)
        rows = data.to_a
      elsif data.respond_to?(:each)
        rows = []
        # MAYBE/2017-07-02: Does shover operator work on frozen string literals?
        data.each { |i| rows << i }
      else
        error TABULARIZE_DATA_FORMAT_ERROR
        return
      end
      if fmt =~ /csv/i
        cols = [] if cols.nil?
        rows = [[]] if rows.nil?
        CSV(ios, headers: cols, write_headers: !cols.empty?) do |csv|
          # MAYBE/2017-07-02: Does shover operator work on frozen string literals?
          rows.each { |v| csv << v }
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
    def outf(obj, ios=nil, &_block)
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
        if block_given?
          yield obj, ios
        elsif obj.is_a?(Array)
          obj.each { |i| ios.puts i.to_s }
        else
          ios.puts obj.to_s
        end
      end
    end

    def self.ask_yes_no(question, default)
      confirm = ask(question)
      if default
        answer = ['', 'y', 'ye', 'yes'].include?(confirm.downcase)
      else
        answer = !['', 'n', 'no'].include?(confirm.downcase)
      end
      answer
    end

    def ask_yes_no(question, default)
      MrMurano::Verbose.ask_yes_no(question, default)
    end

    def self.pluralize?(word, count)
      count == 1 && word || Inflecto.pluralize(word)
    end

    def pluralize?(word, count)
      MrMurano::Verbose.pluralize?(word, count)
    end

    # 2017-07-01: Whirly wrappers. Maybe delete someday.

    def whirly_start(msg)
      MrMurano::Progress.instance.whirly_start(msg)
    end

    def whirly_stop(force: false)
      MrMurano::Progress.instance.whirly_stop(force: force)
    end

    def whirly_linger
      MrMurano::Progress.instance.whirly_linger
    end

    def whirly_msg(msg)
      MrMurano::Progress.instance.whirly_msg(msg)
    end

    def self.whirly_start(msg)
      MrMurano::Progress.instance.whirly_start(msg)
    end

    def self.whirly_stop(force: false)
      MrMurano::Progress.instance.whirly_stop(force: force)
    end

    def self.whirly_linger
      MrMurano::Progress.instance.whirly_linger
    end

    def self.whirly_msg(msg)
      MrMurano::Progress.instance.whirly_msg(msg)
    end
  end
end

