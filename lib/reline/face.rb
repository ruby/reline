class Reline::Face
  SGR_PARAMETERS = {
    # Foreground
    black_foreground: 30,
    red_foreground: 31,
    green_foreground: 32,
    yellow_foreground: 33,
    blue_foreground: 34,
    magenta_foreground: 35,
    cyan_foreground: 36,
    white_foreground: 37,
    bright_black_foreground: 90,
    gray_foreground: 90,
    bright_red_foreground: 91,
    bright_green_foreground: 92,
    bright_yellow_foreground: 93,
    bright_blue_foreground: 94,
    bright_magenta_foreground: 95,
    bright_cyan_foreground: 96,
    bright_white_foreground: 97,
    # Background
    black_background: 40,
    red_background: 41,
    green_background: 42,
    yellow_background: 43,
    blue_background: 44,
    magenta_background: 45,
    cyan_background: 46,
    white_background: 47,
    bright_black_background: 100,
    gray_background: 100,
    bright_red_background: 101,
    bright_green_background: 102,
    bright_yellow_background: 103,
    bright_blue_background: 104,
    bright_magenta_background: 105,
    bright_cyan_background: 106,
    bright_white_background: 107,
    # Style
    default: 0,
    bold: 1,
    faint: 2,
    italicized: 3,
    underlined: 4,
    slowly_blinking: 5,
    blinking: 5,
    rapidly_blinking: 6,
    negative: 7,
    concealed: 8,
    crossed_out: 9
  }.freeze

  class FaceConfig
    def initialize(name, &block)
      @name = name
      block.call(self)
      define(:default) unless self.respond_to?(:default)
    end

    def define(name, *sgr_values)
      sgr_values.each do |value|
        sgr_valid?(value) or raise ArgumentError, "invalid SGR parameter: #{value.inspect}"
      end
      sgr = "\e[" + sgr_values.map { |value|
        case value
        when Symbol
          SGR_PARAMETERS[value]
        when Hash
          key, v = value.first
          sgr_rgb(key, v)
        end
      }.join(';') + "m"
      define_singleton_method(name) { sgr }
    end

    private

    def sgr_rgb(key, value)
      case key
      when :foreground
       "38;2;"
      when :background
        "48;2;"
      end + value[1, 6].scan(/../).map(&:hex).join(";")
    end

    def sgr_valid?(sgr_value)
      case sgr_value
      when Symbol
        SGR_PARAMETERS.keys.include?(sgr_value)
      when Hash
        sgr_value.count == 1 or return false
        key, value = sgr_value.first
        %i(foreground background).include?(key) or return false
        rgb?(value) or return false
      else
        false
      end
    end

    def rgb?(color)
      color.respond_to?(:match?) and color.match?(/\A#[0-9a-fA-F]{6}\z/)
    end
  end

  CONFIGS = {}

  private_constant :SGR_PARAMETERS, :FaceConfig, :CONFIGS

  def self.[](name)
    CONFIGS[name]
  end

  def self.config(name, override = true, &block)
    return if CONFIGS[name] && !override
    CONFIGS[name] = FaceConfig.new(name, &block)
  end

end

