class Reline::KeyActor::Base
  def initialize
    @matching_bytes = {}
    @key_bindings = {}
  end

  def add_mappings(mappings)
    add([27], :ed_ignore)
    128.times do |key|
      func = mappings[key]
      meta_func = mappings[key | 0b10000000]
      add([key], func) unless func == :ed_unassigned
      add([27, key], meta_func) unless meta_func == :ed_unassigned
    end
  end

  def add(key, func)
    (1...key.size).each do |size|
      @matching_bytes[key.take(size)] = true
    end
    @key_bindings[key] = func
  end

  def matching?(key)
    @matching_bytes[key]
  end

  def get(key)
    @key_bindings[key]
  end

  def clear
    @matching_bytes.clear
    @key_bindings.clear
  end
end
