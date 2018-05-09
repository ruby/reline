class Reline::KeyActor::Base
  MAPPING = Array.new(256)

  def self.get_method(key)
    a = self::MAPPING[key]
    self::MAPPING[key]
  end
end
