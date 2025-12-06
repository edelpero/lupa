module Lupa
  # Base class for creating search filters using object-oriented design patterns.
  #
  # Lupa::Search provides a structured way to build complex search functionality
  # by defining search methods in a nested Scope class. Each search attribute
  # maps to a method in the Scope class, allowing for clean, testable, and
  # maintainable search logic.
  #
  # = Basic Structure
  #
  # To create a search class:
  # 1. Inherit from `Lupa::Search`
  # 2. Define a nested `Scope` class
  # 3. Implement search methods in the Scope class
  # 4. Optionally define `default_search_attributes`
  #
  # = Features
  #
  # - Framework and ORM agnostic
  # - Works with any object that supports method chaining (ActiveRecord, Array, etc.)
  # - Automatic attribute symbolization and blank value filtering
  # - Support for nested hash attributes
  # - Default search attributes and default scope
  # - Search class composition for reusability
  # - Method delegation to search results
  #
  # @example Basic search class
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def name
  #         scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
  #       end
  #
  #       def category
  #         scope.where(category_id: search_attributes[:category])
  #       end
  #
  #       def in_stock
  #         scope.where(in_stock: search_attributes[:in_stock])
  #       end
  #     end
  #   end
  #
  #   # Usage
  #   search = ProductSearch.new(Product.all).search(name: 'chair', category: '23')
  #   search.results  # => ActiveRecord::Relation
  #   search.first    # => Product instance (delegates to results)
  #   search.count    # => 5 (delegates to results)
  #
  # @example With default scope
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def name
  #         scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
  #       end
  #     end
  #
  #     def initialize(scope = Product.where(active: true))
  #       @scope = scope
  #     end
  #   end
  #
  #   # Can use class method without passing scope
  #   search = ProductSearch.search(name: 'chair')
  #
  # @example With default search attributes
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def category
  #         scope.where(category_id: search_attributes[:category])
  #       end
  #
  #       def in_stock
  #         scope.where(in_stock: search_attributes[:in_stock])
  #       end
  #     end
  #
  #     def default_search_attributes
  #       { in_stock: true }
  #     end
  #   end
  #
  #   # in_stock will always be applied unless overridden
  #   search = ProductSearch.new(Product.all).search(category: '23')
  #   search.search_attributes  # => { category: '23', in_stock: true }
  #
  # @example Composing search classes
  #   class DateRangeSearch < Lupa::Search
  #     class Scope
  #       def created_between
  #         return scope unless start_date && end_date
  #         scope.where(created_at: start_date..end_date)
  #       end
  #
  #       private
  #         def start_date
  #           search_attributes[:created_between][:start_date]&.to_date
  #         end
  #
  #         def end_date
  #           search_attributes[:created_between][:end_date]&.to_date
  #         end
  #     end
  #   end
  #
  #   class ProductSearch < Lupa::Search
  #     class Scope
  #       def name
  #         scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
  #       end
  #
  #       def created_between
  #         DateRangeSearch.new(scope)
  #           .search(created_between: search_attributes[:created_between])
  #           .results
  #       end
  #     end
  #   end
  #
  # @example Searching arrays
  #   numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  #
  #   class NumberSearch < Lupa::Search
  #     class Scope
  #       def even
  #         return scope unless search_attributes[:even]
  #         scope.select(&:even?)
  #       end
  #
  #       def greater_than
  #         return scope unless search_attributes[:greater_than]
  #         scope.select { |n| n > search_attributes[:greater_than] }
  #       end
  #     end
  #   end
  #
  #   search = NumberSearch.new(numbers).search(even: true, greater_than: 5)
  #   search.results  # => [6, 8, 10]
  #
  # @author Ezequiel Delpero
  # @since 0.1.0
  class Search
    # Base class for defining search scope methods.
    # All search classes must define a nested Scope class that inherits from this.
    #
    # @example
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def name
    #         scope.where(name: search_attributes[:name])
    #       end
    #     end
    #   end
    class Scope; end

    # Returns the original scope object passed to the search class.
    # This is the base scope that all search methods will operate on.
    #
    # @return [Object] the original scope object (e.g., ActiveRecord::Relation, Array)
    #
    # @example Getting the scope
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #     end
    #   end
    #
    #   products = Product.where(active: true)
    #   search = ProductSearch.new(products).search(category: 'furniture')
    #   search.scope  # => #<Product::ActiveRecord_Relation [...]> (original products scope)
    #
    # @example With arrays
    #   numbers = [1, 2, 3, 4, 5]
    #   search = NumberSearch.new(numbers).search(even: true)
    #   search.scope  # => [1, 2, 3, 4, 5] (original array)
    #
    # @note This returns the original scope, not the filtered results.
    #   Use `results` to get the filtered scope after search methods are applied.
    attr_reader :scope

    # Returns all search attributes including default search attributes.
    # All keys are automatically symbolized and blank values are removed.
    #
    # @return [Hash] the search attributes hash with symbolized keys
    #
    # @example Basic usage
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def name
    #         scope.where(name: search_attributes[:name])
    #       end
    #     end
    #   end
    #
    #   search = ProductSearch.new(Product.all).search('name' => 'chair')
    #   search.search_attributes  # => { name: 'chair' }
    #
    # @example With default search attributes
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category_id: search_attributes[:category])
    #       end
    #
    #       def in_stock
    #         scope.where(in_stock: search_attributes[:in_stock])
    #       end
    #     end
    #
    #     def default_search_attributes
    #       { in_stock: true }
    #     end
    #   end
    #
    #   search = ProductSearch.new(Product.all).search(category: 'furniture')
    #   search.search_attributes  # => { category: 'furniture', in_stock: true }
    #
    # @example Blank values are removed
    #   search = ProductSearch.new(Product.all).search(name: 'chair', category: '')
    #   search.search_attributes  # => { name: 'chair' }
    #
    # @example Nested hash attributes
    #   search = ProductSearch.new(Product.all).search(
    #     created_between: { start_date: '2023-01-01', end_date: '2023-12-31' }
    #   )
    #   search.search_attributes
    #   # => { created_between: { start_date: '2023-01-01', end_date: '2023-12-31' } }
    attr_reader :search_attributes

    # Creates a new search instance with the given scope.
    #
    # The scope can be any object that supports method chaining, such as an
    # ActiveRecord::Relation, Mongoid::Criteria, or even a plain Ruby Array.
    #
    # @param scope [Object] the object to perform search operations on
    #
    # @return [Lupa::Search] a new search instance
    #
    # @example With ActiveRecord
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category_id: search_attributes[:category])
    #       end
    #     end
    #   end
    #
    #   products = Product.where(price: 20..30)
    #   search = ProductSearch.new(products)
    #
    # @example With a scoped relation
    #   active_products = Product.where(active: true).includes(:category)
    #   search = ProductSearch.new(active_products).search(name: 'chair')
    #
    # @example With arrays
    #   numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    #   search = NumberSearch.new(numbers).search(even: true)
    #
    # @example Defining a default scope
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category_id: search_attributes[:category])
    #       end
    #     end
    #
    #     def initialize(scope = Product.where(active: true))
    #       @scope = scope
    #     end
    #   end
    #
    #   # Can now use without passing a scope
    #   search = ProductSearch.search(category: '23')
    def initialize(scope)
      @scope = scope
    end

    # Returns default search attributes that should always be applied.
    #
    # Override this method in your search class to define attributes that should
    # always be included in the search, regardless of what's passed to the `search` method.
    # Default attributes can be overridden by explicitly passing them in search params.
    #
    # @return [Hash] a hash of default search attributes (empty hash by default)
    #
    # @raise [Lupa::DefaultSearchAttributesError] if the return value is not a Hash
    #
    # @example Defining default search attributes
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category_id: search_attributes[:category])
    #       end
    #
    #       def in_stock
    #         scope.where(in_stock: search_attributes[:in_stock])
    #       end
    #     end
    #
    #     def default_search_attributes
    #       { in_stock: true }
    #     end
    #   end
    #
    #   search = ProductSearch.new(Product.all).search(category: 'furniture')
    #   search.default_search_attributes  # => { in_stock: true }
    #   search.search_attributes          # => { category: 'furniture', in_stock: true }
    #
    # @example Overriding default attributes
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def status
    #         scope.where(status: search_attributes[:status])
    #       end
    #     end
    #
    #     def default_search_attributes
    #       { status: 'active' }
    #     end
    #   end
    #
    #   # Using default
    #   search = ProductSearch.new(Product.all).search({})
    #   search.search_attributes  # => { status: 'active' }
    #
    #   # Overriding default
    #   search = ProductSearch.new(Product.all).search(status: 'archived')
    #   search.search_attributes  # => { status: 'archived' }
    #
    # @example Using with conditional defaults
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def visibility
    #         scope.where(visibility: search_attributes[:visibility])
    #       end
    #     end
    #
    #     def initialize(scope = Product.all, current_user: nil)
    #       @scope = scope
    #       @current_user = current_user
    #     end
    #
    #     def default_search_attributes
    #       return { visibility: 'public' } unless @current_user&.admin?
    #       {}
    #     end
    #   end
    #
    # @note This method must return a Hash or a Lupa::DefaultSearchAttributesError will be raised
    def default_search_attributes
      {}
    end

    # Performs the search with the given attributes.
    #
    # This method processes the search attributes (symbolizing keys, merging with
    # defaults, removing blank values), validates that all attribute keys have
    # corresponding methods in the Scope class, and returns self for method chaining.
    #
    # @param attributes [Hash] the search parameters to apply
    #
    # @return [self] returns the search instance for method chaining
    #
    # @raise [Lupa::SearchAttributesError] if attributes doesn't respond to `keys` method
    # @raise [Lupa::ScopeMethodNotImplementedError] if an attribute key doesn't have
    #   a corresponding method in the Scope class
    # @raise [Lupa::DefaultSearchAttributesError] if `default_search_attributes` doesn't return a Hash
    #
    # @example Basic usage
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
    #   search = ProductSearch.new(Product.all).search(name: 'chair', category: '23')
    #   # Returns the search instance for further operations
    #
    # @example Method chaining
    #   products = ProductSearch.new(Product.all)
    #     .search(name: 'chair', category: '23')
    #     .results
    #
    # @example Accessing results through delegation
    #   search = ProductSearch.new(Product.all).search(name: 'chair')
    #   search.first     # Delegates to results.first
    #   search.count     # Delegates to results.count
    #   search.each { |p| puts p.name }  # Delegates to results.each
    #
    # @example String keys are symbolized
    #   search = ProductSearch.new(Product.all).search('name' => 'chair', 'category' => '23')
    #   search.search_attributes  # => { name: 'chair', category: '23' }
    #
    # @example Blank values are removed
    #   search = ProductSearch.new(Product.all).search(name: 'chair', category: '', price: nil)
    #   search.search_attributes  # => { name: 'chair' }
    #
    # @example Nested hash attributes
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def created_between
    #         start_date = search_attributes[:created_between][:start_date]
    #         end_date = search_attributes[:created_between][:end_date]
    #         scope.where(created_at: start_date..end_date)
    #       end
    #     end
    #   end
    #
    #   search = ProductSearch.new(Product.all).search(
    #     created_between: { start_date: '2023-01-01', end_date: '2023-12-31' }
    #   )
    #
    # @example Error handling - invalid attributes type
    #   ProductSearch.new(Product.all).search("not a hash")
    #   # => Lupa::SearchAttributesError: Your search params needs to be a hash.
    #
    # @example Error handling - undefined scope method
    #   ProductSearch.new(Product.all).search(undefined_attribute: 'value')
    #   # => Lupa::ScopeMethodNotImplementedError: undefined_attribute is not defined on your ProductSearch::Scope class.
    #
    # @note Search methods are not executed until you call `results` or a delegated method
    def search(attributes)
      raise Lupa::SearchAttributesError, "Your search params needs to be a hash." unless attributes.respond_to?(:keys)

      set_search_attributes(attributes)
      set_scope_class
      check_method_definitions
      self
    end

    # Class method to create a new search instance and perform a search in one call.
    #
    # This is a convenience method that creates a new instance without a scope parameter
    # and then calls the instance `search` method. This only works if you've defined
    # a default scope in your `initialize` method.
    #
    # @param attributes [Hash] the search parameters to apply
    #
    # @return [Lupa::Search] the search instance with applied search attributes
    #
    # @raise [Lupa::DefaultScopeError] if no default scope is defined in `initialize`
    # @raise [Lupa::SearchAttributesError] if attributes doesn't respond to `keys` method
    # @raise [Lupa::ScopeMethodNotImplementedError] if an attribute key doesn't have
    #   a corresponding method in the Scope class
    #
    # @example With default scope defined
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category_id: search_attributes[:category])
    #       end
    #
    #       def name
    #         scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
    #       end
    #     end
    #
    #     def initialize(scope = Product.where(active: true))
    #       @scope = scope
    #     end
    #   end
    #
    #   # Can use the class method
    #   search = ProductSearch.search(category: 'furniture', name: 'chair')
    #   search.results  # => filtered products
    #
    # @example Without default scope (will raise error)
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category_id: search_attributes[:category])
    #       end
    #     end
    #     # No default scope in initialize
    #   end
    #
    #   ProductSearch.search(category: 'furniture')
    #   # => Lupa::DefaultScopeError: You need to define a default scope in order to user search class method.
    #
    # @example Chaining with results
    #   products = ProductSearch.search(category: 'furniture').results
    #   products.each { |p| puts p.name }
    #
    # @example Using delegation
    #   # These all work because of method delegation to results
    #   ProductSearch.search(category: 'furniture').first
    #   ProductSearch.search(category: 'furniture').count
    #   ProductSearch.search(category: 'furniture').each { |p| puts p.name }
    #
    # @note If you need to pass a custom scope, use `ProductSearch.new(scope).search(attributes)` instead
    def self.search(attributes)
      new.search(attributes)
    rescue ArgumentError
      raise Lupa::DefaultScopeError, "You need to define a default scope in order to user search class method."
    end

    # Returns the search results after applying all search methods.
    #
    # This method executes the search by calling each method defined in the Scope class
    # that corresponds to a key in search_attributes. The methods are called in the
    # order they appear in the search_attributes hash. Results are memoized, so
    # calling this method multiple times won't re-execute the search.
    #
    # @return [Object] the filtered scope (e.g., ActiveRecord::Relation, Array)
    #
    # @raise [Lupa::SearchAttributesError] if search attributes weren't set
    #
    # @example Basic usage
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category_id: search_attributes[:category])
    #       end
    #
    #       def name
    #         scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
    #       end
    #     end
    #   end
    #
    #   search = ProductSearch.new(Product.all).search(category: 'furniture', name: 'chair')
    #   search.results  # => #<Product::ActiveRecord_Relation:0x007ffda11b7d48>
    #
    # @example Results are memoized
    #   search = ProductSearch.new(Product.all).search(category: 'furniture')
    #   results1 = search.results  # Executes the search
    #   results2 = search.results  # Returns cached results (same object)
    #   results1.object_id == results2.object_id  # => true
    #
    # @example With arrays
    #   class NumberSearch < Lupa::Search
    #     class Scope
    #       def even
    #         return scope unless search_attributes[:even]
    #         scope.select(&:even?)
    #       end
    #
    #       def greater_than
    #         return scope unless search_attributes[:greater_than]
    #         scope.select { |n| n > search_attributes[:greater_than] }
    #       end
    #     end
    #   end
    #
    #   search = NumberSearch.new([1, 2, 3, 4, 5, 6]).search(even: true, greater_than: 2)
    #   search.results  # => [4, 6]
    #
    # @example Scope methods returning nil are handled gracefully
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def optional_filter
    #         # If condition not met, return nil - scope won't be updated
    #         return nil unless search_attributes[:optional_filter]
    #         scope.where(some_field: search_attributes[:optional_filter])
    #       end
    #     end
    #   end
    #
    # @note Methods in your Scope class should return either the modified scope
    #   or nil (if no filtering should be applied). Returning nil prevents the
    #   scope from being updated for that particular search method.
    def results
      @results ||= run
    end

    # Delegates method calls to the search results.
    #
    # This allows you to call any method that the results object responds to
    # directly on the search instance, making the search object behave like
    # the results collection.
    #
    # @param method_sym [Symbol] the method name to delegate
    # @param arguments [Array] arguments to pass to the delegated method
    # @param block [Proc] block to pass to the delegated method
    #
    # @return [Object] the return value of the delegated method
    #
    # @raise [Lupa::ResultMethodNotImplementedError] if the results don't respond to the method
    #
    # @example Delegating Array/Relation methods
    #   class ProductSearch < Lupa::Search
    #     class Scope
    #       def category
    #         scope.where(category_id: search_attributes[:category])
    #       end
    #     end
    #
    #     def initialize(scope = Product.all)
    #       @scope = scope
    #     end
    #   end
    #
    #   search = ProductSearch.search(category: 'furniture')
    #
    #   # All these methods are delegated to results
    #   search.first     # => #<Product:0x007f9c0ce1b1a8>
    #   search.count     # => 42
    #   search.empty?    # => false
    #   search.pluck(:name)  # => ["Chair", "Table", ...]
    #
    # @example Iterating with blocks
    #   search = ProductSearch.search(category: 'furniture')
    #
    #   search.each do |product|
    #     puts product.name
    #   end
    #
    #   search.map(&:name)  # => ["Chair", "Table", ...]
    #
    # @example Error when method doesn't exist
    #   search = ProductSearch.search(category: 'furniture')
    #   search.non_existent_method
    #   # => Lupa::ResultMethodNotImplementedError: The resulting scope does not respond to non_existent_method method.
    #
    # @example Chaining delegated methods
    #   search = ProductSearch.search(category: 'furniture')
    #   search.limit(10).offset(20).to_a
    #   # All these methods are delegated to the results
    #
    # @note This is what allows search objects to be used directly in views
    #   without explicitly calling `.results` first
    def method_missing(method_sym, *arguments, &block)
      if results.respond_to?(method_sym)
        results.send(method_sym, *arguments, &block)
      else
        raise Lupa::ResultMethodNotImplementedError, "The resulting scope does not respond to #{method_sym} method."
      end
    end

    private
      # Stores the instantiated Scope class that contains all search methods.
      #
      # @return [Lupa::Search::Scope] the scope class instance
      #
      # @api private
      attr_accessor :scope_class

      # Processes and sets search attributes by merging with defaults, symbolizing keys,
      # and removing blank values.
      #
      # @param attributes [Hash] the raw search attributes
      #
      # @return [Hash] the processed search attributes
      #
      # @api private
      #
      # @example Internal usage
      #   # Given a search class with default_search_attributes { in_stock: true }
      #   set_search_attributes('category' => 'furniture', 'name' => '')
      #   # Results in: { category: 'furniture', in_stock: true }
      #   # - Merged with defaults
      #   # - Keys symbolized
      #   # - Blank 'name' removed
      def set_search_attributes(attributes)
        attributes = merge_search_attributes(attributes)
        attributes = symbolize_keys(attributes)
        attributes = remove_blank_attributes(attributes)

        @search_attributes = attributes
      end

      # Merges the provided attributes with default search attributes.
      # Default attributes can be overridden by explicitly providing them.
      #
      # @param attributes [Hash] the attributes to merge with defaults
      #
      # @return [Hash] the merged attributes hash
      #
      # @raise [Lupa::DefaultSearchAttributesError] if default_search_attributes
      #   doesn't return a Hash
      #
      # @api private
      def merge_search_attributes(attributes)
        return default_search_attributes.merge(attributes) if default_search_attributes.kind_of?(Hash)

        raise Lupa::DefaultSearchAttributesError, "default_search_attributes doesn't return a Hash."
      end

      # Recursively symbolizes all hash keys in the attributes.
      # Works with nested hashes and arrays.
      #
      # @param attributes [Hash, Array, Object] the attributes to symbolize
      #
      # @return [Hash, Array, Object] attributes with symbolized keys
      #
      # @api private
      #
      # @example With nested hash
      #   symbolize_keys('name' => 'chair', 'range' => { 'min' => 10, 'max' => 20 })
      #   # => { name: 'chair', range: { min: 10, max: 20 } }
      #
      # @example With array
      #   symbolize_keys([{ 'id' => 1 }, { 'id' => 2 }])
      #   # => [{ id: 1 }, { id: 2 }]
      def symbolize_keys(attributes)
        return attributes.reduce({}) do |attribute, (key, value)|
          attribute.tap { |a| a[key.to_sym] = symbolize_keys(value) }
        end if attributes.is_a? Hash

        return attributes.reduce([]) do |attribute, value|
          attribute << symbolize_keys(value); attribute
        end if attributes.is_a? Array

        attributes
      end

      # Removes all blank values from the attributes hash.
      # A value is considered blank if it's an empty string, nil, or a hash/array
      # that contains only blank values.
      #
      # @param attributes [Hash] the attributes to clean
      #
      # @return [Hash] attributes with blank values removed
      #
      # @api private
      #
      # @example
      #   remove_blank_attributes(name: 'chair', category: '', price: nil, tags: [])
      #   # => { name: 'chair' }
      def remove_blank_attributes(attributes)
        attributes.delete_if { |key, value| clean_attribute(value) }
      end

      # Recursively determines if a value is blank (empty or contains only blank values).
      # Modifies hashes and arrays in place by removing blank values.
      #
      # @param value [Object] the value to check
      #
      # @return [Boolean] true if the value is blank, false otherwise
      #
      # @api private
      #
      # @example With hash
      #   clean_attribute({ min: '', max: '' })  # => true
      #   clean_attribute({ min: 10, max: '' })  # => false
      #
      # @example With array
      #   clean_attribute(['', nil, '  '])  # => true
      #   clean_attribute(['valid', ''])    # => false
      #
      # @example With strings
      #   clean_attribute('')       # => true
      #   clean_attribute('  ')     # => true
      #   clean_attribute('value')  # => false
      def clean_attribute(value)
        if value.kind_of?(Hash)
          value.delete_if { |key, value| clean_attribute(value) }.empty?
        elsif value.kind_of?(Array)
          value.delete_if { |value| clean_attribute(value) }.empty?
        else
          value.to_s.strip.empty?
        end
      end

      # Includes the ScopeMethods module into the Scope class and instantiates it.
      #
      # This method dynamically includes the ScopeMethods module which provides
      # access to `scope` and `search_attributes` within scope methods.
      #
      # @return [Lupa::Search::Scope] the instantiated scope class
      #
      # @api private
      def set_scope_class
        klass = self.class::Scope
        klass.send(:include, ScopeMethods)
        @scope_class = klass.new(@scope, @search_attributes)
      end

      # Validates that all search attribute keys have corresponding methods in the Scope class.
      #
      # @return [void]
      #
      # @raise [Lupa::ScopeMethodNotImplementedError] if a search attribute doesn't
      #   have a corresponding method in the Scope class
      #
      # @api private
      #
      # @example Valid methods
      #   # Given search_attributes: { name: 'chair', category: '23' }
      #   # The Scope class must have both `name` and `category` methods defined
      #
      # @example Error case
      #   # Given search_attributes: { undefined_method: 'value' }
      #   # Raises: Lupa::ScopeMethodNotImplementedError: undefined_method is not defined on your ProductSearch::Scope class.
      def check_method_definitions
        method_names = search_attributes.keys

        method_names.each do |method_name|
          next if scope_class.respond_to?(method_name)
          raise Lupa::ScopeMethodNotImplementedError, "#{method_name} is not defined on your #{self.class}::Scope class."
        end
      end

      # Executes the search by calling each scope method corresponding to the search attributes.
      #
      # Iterates through each key in search_attributes and calls the corresponding
      # method on the scope_class. If a method returns nil, the scope is not updated
      # for that particular search attribute.
      #
      # @return [Object] the final filtered scope
      #
      # @raise [Lupa::SearchAttributesError] if search_attributes is not set
      #
      # @api private
      #
      # @example Execution flow
      #   # Given search_attributes: { name: 'chair', category: '23' }
      #   # Calls: scope_class.name
      #   # Then:  scope_class.category
      #   # Returns: scope_class.scope (the final filtered result)
      #
      # @example Handling nil returns
      #   # If a scope method returns nil, the scope doesn't change
      #   def optional_filter
      #     return nil unless some_condition
      #     scope.where(...)
      #   end
      def run
        raise Lupa::SearchAttributesError, "You need to specify search attributes." unless search_attributes

        search_attributes.each do |method_name, value|
          new_scope         = scope_class.public_send(method_name)
          scope_class.scope = new_scope unless new_scope.nil?
        end

        scope_class.scope
      end

  end
end


