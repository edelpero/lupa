module Lupa
  # Internal module that provides common functionality to Scope classes.
  # This module is automatically included in the Scope class defined within
  # your search class.
  #
  # It provides access to two key attributes:
  # - `scope`: The current scope being searched
  # - `search_attributes`: The hash of search parameters
  #
  # @example Accessing scope and search_attributes in a Scope class
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       # scope and search_attributes are available here
  #       def name
  #         # scope is the current ActiveRecord relation (or any chainable object)
  #         scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
  #       end
  #
  #       def price_range
  #         # search_attributes contains all search parameters
  #         if search_attributes[:price_range]
  #           scope.where(price: search_attributes[:price_range])
  #         else
  #           scope
  #         end
  #       end
  #     end
  #   end
  #
  # @note This module is included automatically by Lupa and should not be
  #   included manually in your code.
  #
  # @api private
  # @since 0.1.0
  module ScopeMethods
    # @!attribute [rw] scope
    #   The current scope object that search methods will operate on.
    #   This is typically an ActiveRecord::Relation or similar chainable object.
    #   The scope is updated after each search method is called.
    #
    #   @return [Object] the current scope object
    #
    #   @example Accessing the scope in a search method
    #     def category
    #       # scope is the current state of the query chain
    #       scope.where(category_id: search_attributes[:category])
    #     end
    attr_accessor :scope

    # @!attribute [r] search_attributes
    #   A hash containing all search attributes, including default search attributes.
    #   All keys are symbolized automatically by Lupa.
    #
    #   @return [Hash] the search attributes hash with symbolized keys
    #
    #   @example Accessing search attributes in a scope method
    #     def search_by_name
    #       name = search_attributes[:name]
    #       scope.where('name LIKE ?', "%#{name}%") if name.present?
    #     end
    #
    #   @example With nested hash attributes
    #     def created_between
    #       start_date = search_attributes[:created_between][:start_date]
    #       end_date = search_attributes[:created_between][:end_date]
    #       scope.where(created_at: start_date..end_date)
    #     end
    attr_reader :search_attributes

    # Initializes a new Scope instance with the given scope and search attributes.
    # This method is called automatically by Lupa::Search and should not be called directly.
    #
    # @param scope [Object] the initial scope object to search on (e.g., ActiveRecord::Relation)
    # @param search_attributes [Hash] the hash of search parameters with symbolized keys
    #
    # @return [ScopeMethods] the initialized scope instance
    #
    # @example Internal usage (automatically called by Lupa)
    #   # This happens internally when you call:
    #   ProductSearch.new(Product.all).search(name: 'chair')
    #   # Lupa automatically calls:
    #   ProductSearch::Scope.new(Product.all, { name: 'chair' })
    #
    # @api private
    def initialize(scope, search_attributes)
      @scope             = scope
      @search_attributes = search_attributes
    end
  end
end
