require 'minitest/autorun'

def context(*args, &block)
  describe(*args, &block)
end

$:.unshift File.expand_path('../../lib', __FILE__)

require 'lupa'

