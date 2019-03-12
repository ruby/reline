require 'helper'

class Reline::Config::Test < Reline::TestCase
  def setup
    @tmpdir = File.join(Dir.tmpdir, "test_reline_config_#{$$}")
    Dir.mkdir(@tmpdir)
    Dir.chdir(@tmpdir)
    @config = Reline::Config.new
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_read_lines
  end
end
