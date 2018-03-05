require 'io/console'
require 'reline/version'
require 'reline/readline'

module Reline
  FILENAME_COMPLETION_PROC = nil
  USERNAME_COMPLETION_PROC = nil
  HISTORY = Array.new

  class << self
    attr_accessor :basic_quote_characters
    attr_accessor :basic_word_break_characters
    attr_accessor :completer_quote_characters
    attr_accessor :completer_word_break_characters
    attr_accessor :completion_append_character
    attr_accessor :completion_case_fold
    attr_accessor :completion_proc
    attr_accessor :filename_quote_characters
    attr_writer :input
    attr_writer :output
  end

  def self.vi_editing_mode
    nil
  end

  def self.emacs_editing_mode
    nil
  end

  def self.get_screen_size
    [Integer, Integer]
  end

  def self.set_screen_size(rows, columns)
    self
  end

  def self.readline(prompt = '', add_hist = false)
    readline = Reline::Readline.new(prompt, add_hist)
    readline.run
  end
end
