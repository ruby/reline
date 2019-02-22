class Reline::Config
  DEFAULT_PATH = Pathname.new(Dir.home).join('.inputrc')

  def initialize
  end

  def read(path = DEFAULT_PATH)
    f = File.open(path, 'rt')
    unless f
      $stderr.puts "no such file #{path}"
    end
    lines = f.readlines
    f.close
  end
end
