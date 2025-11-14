require 'reline'

puts 'Welcome to the Echo program!'
puts '  To exit, type Ctrl-d in empty line.'

# Words for completion.
Words = %w[ foo_foo foo_bar foo_baz qux ]
Reline.completion_proc = proc { |word| Words }

# REPL (Read-Evaluate-Print Loop).
while line = Reline.readline(prompt = 'echo> ', history = true)
  puts "You typed: '#{line.chomp}'."
end
