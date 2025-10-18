require 'reline'
require 'open-uri'

# Get words for completion.
words_url = 'https://raw.githubusercontent.com/first20hours/google-10000-english/refs/heads/master/google-10000-english-usa-no-swears-long.txt'
words = []
URI.open(words_url) do |file|
  while !file.eof?
    words.push(file.readline.chomp)
  end
end
# Install completion proc.
Reline.completion_proc = proc { |word|
  words
}
puts 'Welcome to the Echo program!'
puts '  To exit, type Ctrl-d in empty line.'
# REPL (Read-Evaluate-Print Loop)
while line = Reline.readline(prompt = 'echo> ', history = true)
  line.chomp!
  puts "You typed: '#{line}'."
end
