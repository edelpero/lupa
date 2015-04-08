module Lupa
  module ScopeMethods

    attr_accessor :scope
    attr_reader   :search_attributes

    def initialize(scope, search_attributes)
      @scope             = scope
      @search_attributes = search_attributes
    end

  end
end
