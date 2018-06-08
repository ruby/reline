require 'helper'

class Reline::KillRing::Test < Reline::TestCase
  def setup
    @prompt = '> '
    @kill_ring = Reline::KillRing.new
  end
end
