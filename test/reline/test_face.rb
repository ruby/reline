require_relative 'helper'

class Reline::Face::Test < Reline::TestCase
  class WithSetupTest < self
    def setup
      Reline::Face.config(:my_config) do |face|
        face.define :default, :blue_foreground
        face.define :enhanced, { foreground: "#FF1020" }, :black_background, :bold, :underlined
      end
      Reline::Face.config(:another_config) do |face|
        face.define :another_label, :red_foreground
      end
      @face = Reline::Face[:my_config]
    end

    def test_my_config_line
      assert_equal "\e[34m", @face.default
    end

    def test_my_config_enhanced
      assert_equal "\e[38;2;255;16;32;40;1;4m", @face.enhanced
    end

    def test_not_respond_to_another_label
      assert_equal false, @face.respond_to?(:another_label)
    end

    def test_existing_confit_override_default
      Reline::Face.config(:my_config) do |face|
        face.define :default, :red_foreground
      end
      assert_equal "\e[31m", Reline::Face[:my_config].default
    end

    def test_existing_config_override_false
      Reline::Face.config(:my_config, false) do |face|
        face.define :default, :red_foreground
      end
      assert_equal "\e[34m", Reline::Face[:my_config].default
    end

    def test_new_config_override_false
      Reline::Face.config(:new_config, false) do |face|
        face.define :default, :red_foreground
      end
      assert_equal "\e[31m", Reline::Face[:new_config].default
    end
  end

  class WithoutSetupTest < self
    def test_my_config_default
      Reline::Face.config(:my_config) do |face|
        # do nothing
      end
      face = Reline::Face[:my_config]
      assert_equal "\e[m", face.default
    end

    def test_invalid_foreground_name
      assert_raise ArgumentError do
        Reline::Face.config(:invalid_config) do |face|
          face.define :default, :invalid_foreground
        end
      end
    end

    def test_invalid_background_name
      assert_raise ArgumentError do
        Reline::Face.config(:invalid_config) do |face|
          face.define :default, :invalid_background
        end
      end
    end

    def test_private_constants
      [:SGR_PARAMETER, :FaceConfig, :CONFIGS].each do |name|
        assert_equal false, Reline::Face.constants.include?(name)
      end
    end
   end

  class FaceConfigTest < self
    def setup
      @face_config = Reline::Face.const_get(:FaceConfig).new(:my_config) { }
    end

    def test_rgb?
      assert_equal true, @face_config.send(:rgb?, "#FFFFFF")
    end

    def test_invalid_rgb?
      assert_equal false, @face_config.send(:rgb?, "FFFFFF")
      assert_equal false, @face_config.send(:rgb?, "#FFFFF")
    end

    def test_sgr_valid?
      assert_equal true, @face_config.send(:sgr_valid?, :white_foreground)
      assert_equal true, @face_config.send(:sgr_valid?, { foreground: "#ffffff" })
    end

    def test_invalid_sgr_valid?
      assert_equal false, @face_config.send(:sgr_valid?, { invalid_key: "#ffffff" })
    end

    def test_sgr_rgb
      assert_equal "38;2;255;255;255", @face_config.send(:sgr_rgb, :foreground, "#ffffff")
      assert_equal "48;2;18;52;86", @face_config.send(:sgr_rgb, :background, "#123456")
    end
  end
end
