# Coveralls gem uses Hash#slice which was added in Ruby 2.5
# Only load Coveralls for Ruby 2.5+
if RUBY_VERSION >= '2.5.0'
  require 'coveralls'
  Coveralls.wear!
end

require 'minitest/autorun'

def context(*args, &block)
  describe(*args, &block)
end

$:.unshift File.expand_path('../../lib', __FILE__)

require 'lupa'

