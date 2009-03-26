require 'test_helper'

class PreserveAttributesTest < ActiveSupport::TestCase
  test "jasmin is installed" do
    assert require('jsmin')
  end
  
  test "jsmin minification" do
    expected = "\nfunction aFunc(){three='3.33333';someString=(parseInt(three)+3).toString+\"Blah\";console.log(\"end\");a=\"this is a s\"}"
    assert (JSMin.minify(File.read('test.js')) == expected)
  end
end
