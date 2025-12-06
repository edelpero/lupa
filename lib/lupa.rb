require "lupa/version"

# Lupa is a Ruby gem that lets you create simple, robust and scaleable search
# filters with ease using regular Ruby classes and object oriented design patterns.
#
# Lupa is Framework and ORM agnostic. It will work with any ORM or Object that
# can build a query using chained method calls, like ActiveRecord.
#
# @example Basic usage with ActiveRecord
#   class ProductSearch < Lupa::Search
#     class Scope
#       def name
#         scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
#       end
#
#       def category
#         scope.where(category_id: search_attributes[:category])
#       end
#     end
#   end
#
#   # Using the search class
#   products = ProductSearch.new(Product.all).search(name: 'chair', category: '23')
#   products.each do |product|
#     puts product.name
#   end
#
# @example With default scope
#   class ProductSearch < Lupa::Search
#     class Scope
#       def name
#         scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
#       end
#     end
#
#     def initialize(scope = Product.all)
#       @scope = scope
#     end
#   end
#
#   # Can now use the class method
#   products = ProductSearch.search(name: 'chair')
#
# @author Ezequiel Delpero
# @since 0.1.0
module Lupa
  # Raised when attempting to use the class method `search` without defining
  # a default scope in the initializer.
  #
  # @example
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def name
  #         scope.where(name: search_attributes[:name])
  #       end
  #     end
  #   end
  #
  #   # This will raise DefaultScopeError because no default scope is defined
  #   ProductSearch.search(name: 'chair')
  #   # => Lupa::DefaultScopeError: You need to define a default scope in order to user search class method.
  DefaultScopeError = Class.new(StandardError)

  # Raised when the `default_search_attributes` method doesn't return a Hash.
  #
  # @example
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def category
  #         scope.where(category_id: search_attributes[:category])
  #       end
  #     end
  #
  #     def default_search_attributes
  #       "not a hash"  # This will raise DefaultSearchAttributesError
  #     end
  #   end
  #
  #   ProductSearch.search(name: 'chair')
  #   # => Lupa::DefaultSearchAttributesError: default_search_attributes doesn't return a Hash.
  DefaultSearchAttributesError = Class.new(StandardError)

  # Raised when a search attribute is passed that doesn't have a corresponding
  # method defined in the Scope class.
  #
  # @example
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def name
  #         scope.where(name: search_attributes[:name])
  #       end
  #     end
  #   end
  #
  #   # This will raise ScopeMethodNotImplementedError because 'color' method is not defined
  #   ProductSearch.new(Product.all).search(name: 'chair', color: 'red')
  #   # => Lupa::ScopeMethodNotImplementedError: color is not defined on your ProductSearch::Scope class.
  ScopeMethodNotImplementedError = Class.new(NotImplementedError)

  # Raised when attempting to call a method on the search results that the
  # resulting scope doesn't respond to.
  #
  # @example
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def name
  #         scope.where(name: search_attributes[:name])
  #       end
  #     end
  #   end
  #
  #   search = ProductSearch.new(Product.all).search(name: 'chair')
  #   search.non_existent_method
  #   # => Lupa::ResultMethodNotImplementedError: The resulting scope does not respond to non_existent_method method.
  ResultMethodNotImplementedError = Class.new(NotImplementedError)

  # Raised when search attributes passed are not a Hash or Hash-like object
  # that responds to the `keys` method.
  #
  # @example
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def name
  #         scope.where(name: search_attributes[:name])
  #       end
  #     end
  #   end
  #
  #   # This will raise SearchAttributesError because "not a hash" doesn't respond to :keys
  #   ProductSearch.new(Product.all).search("not a hash")
  #   # => Lupa::SearchAttributesError: Your search params needs to be a hash.
  SearchAttributesError = Class.new(StandardError)
end

require "lupa/scope_methods"
require "lupa/search"
