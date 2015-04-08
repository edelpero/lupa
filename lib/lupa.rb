require "lupa/version"

module Lupa
  DefaultScopeError               = Class.new(StandardError)
  ScopeMethodNotImplementedError  = Class.new(NotImplementedError)
  ResultMethodNotImplementedError = Class.new(NotImplementedError)
  SearchAttributesError           = Class.new(StandardError)
end

require "lupa/scope_methods"
require "lupa/search"
