class Reline::KeyActor::Base
  MAPPING = Array.new(256)

  def self.get_method(key)
    self::MAPPING[key]
  end
end
