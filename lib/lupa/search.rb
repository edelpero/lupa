module Lupa
  class Search
    class Scope; end

    # Public: Return class scope.
    #
    # === Examples
    #
    #   class ProductSearch < Lupa::Search
    #
    #     class Scope
    #
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #
    #       def in_stock
    #         scope.where(in_stock: search_attributes[:in_stock])
    #       end
    #
    #     end
    #
    #     def default_search_attributes
    #       { in_stock: true }
    #     end
    #
    #   end
    #
    #   search = ProductSearch.new(@products).search({ category: 'furniture' })
    #   search.scope
    #   # => @products
    #
    # Returns your class scope.
    attr_reader :scope

    # Public: Return class search attributes including default search attributes.
    #
    # === Examples
    #
    #   class ProductSearch < Lupa::Search
    #
    #     class Scope
    #
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #
    #       def in_stock
    #         scope.where(in_stock: search_attributes[:in_stock])
    #       end
    #
    #     end
    #
    #     def default_search_attributes
    #       { in_stock: true }
    #     end
    #
    #   end
    #
    #   search = ProductSearch.new(@products).search({ category: 'furniture' })
    #   search.search_attributes
    #   # => { category: furniture, in_stock: true }
    #
    # Returns your class search attributes including default search attributes.
    attr_reader :search_attributes

    # Public: Create a new instance of the class.
    #
    # === Options
    #
    # <tt>scope</tt> - An object which will be use to perform all the search operations.
    #
    # === Examples
    #
    #   class ProductSearch < Lupa::Search
    #
    #     class Scope
    #
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #
    #       def in_stock
    #         scope.where(in_stock: search_attributes[:in_stock])
    #       end
    #
    #     end
    #
    #     def default_search_attributes
    #       { in_stock: true }
    #     end
    #
    #   end
    #
    #   scope  = Product.where(price: 20..30)
    #   search = ProductSearch.new(scope)
    #
    # Returns a new instance of the class.
    def initialize(scope)
      @scope = scope
    end

    # Public: Return default a hash containing default search attributes of the class.
    #
    # === Examples
    #
    #   class ProductSearch < Lupa::Search
    #
    #     class Scope
    #
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #
    #       def in_stock
    #         scope.where(in_stock: search_attributes[:in_stock])
    #       end
    #
    #     end
    #
    #     def default_search_attributes
    #       { in_stock: true }
    #     end
    #
    #   end
    #
    #   scope  = Product.where(price: 20..30)
    #   search = ProductSearch.new(scope).search({ category: 'furniture' })
    #   search.default_search_attributes
    #   # => { in_stock: true }
    #
    # Returns default a hash containing default search attributes of the class.
    def default_search_attributes
      {}
    end

    # Public: Set and checks search attributes, and instantiates the Scope class.
    #
    # === Options
    #
    # <tt>attributes</tt> - The hash containing the search attributes.
    #
    # * If attributes is not a Hash kind of class, it will raise a
    #   Lupa::SearchAttributesError.
    # * If attributes keys don't match methods
    #   defined on your class, it will raise a Lupa::NotImplementedError.
    #
    # === Examples
    #
    #   class ProductSearch < Lupa::Search
    #
    #     class Scope
    #
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #
    #     end
    #
    #   end
    #
    #   scope  = Product.where(price: 20..30)
    #   search = ProductSearch.new(scope).search({ category: 'furniture' })
    #   # => #<ProductSearch:0x007f7f74070850 @scope=scope, @search_attributes={:category=>'furniture'}, @scope_class=#<ProductSearch::Scope:0x007fd2811001e8 @scope=[1, 2, 3, 4, 5, 6, 7, 8], @search_attributes={:even_numbers=>true}>>
    #
    # Returns the class instance itself.
    def search(attributes)
      raise Lupa::SearchAttributesError, "Your search params needs to be a hash." unless attributes.respond_to?(:keys)

      set_search_attributes(attributes)
      set_scope_class
      check_method_definitions
      self
    end

    # Public: Creates a new instance of the search class an applies search method with attributes to it.
    #
    # === Options
    #
    # <tt>attributes</tt> - The hash containing the search attributes.
    #
    # * If search class doesn't have a default scope specified, it will raise a
    #   Lupa::DefaultScopeError exception.
    # * If attributes is not a Hash kind of class, it will raise a
    #   Lupa::SearchAttributesError exception.
    # * If attributes keys don't match methods
    #   defined on your class, it will raise a Lupa::NotImplementedError.
    #
    # === Examples
    #
    #   class ProductSearch < Lupa::Search
    #
    #     class Scope
    #
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #
    #     end
    #
    #     def initialize(scope = Product.in_stock)
    #       @scope = scope
    #     end
    #
    #   end
    #
    #   search = ProductSearch.search({ category: 'furniture' })
    #   # => #<ProductSearch:0x007f7f74070850 @scope=scope, @search_attributes={:category=>'furniture'}, @scope_class=#<ProductSearch::Scope:0x007fd2811001e8 @scope=[1, 2, 3, 4, 5, 6, 7, 8], @search_attributes={:even_numbers=>true}>>
    #
    # Returns the class instance itself.
    def self.search(attributes)
      new.search(attributes)
    rescue ArgumentError
      raise Lupa::DefaultScopeError, "You need to define a default scope in order to user search class method."
    end

    # Public: Return the search result.
    #
    # === Examples
    #
    #   class ProductSearch < Lupa::Search
    #
    #     class Scope
    #
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #
    #     end
    #
    #     def initialize(scope = Product.in_stock)
    #       @scope = scope
    #     end
    #
    #   end
    #
    #   search = ProductSearch.search({ category: 'furniture' }).results
    #   # => #<Product::ActiveRecord_Relation:0x007ffda11b7d48>
    #
    # Returns the search result.
    def results
      @results ||= run
    end

    # Public: Apply the missing method to the search result.
    #
    # === Examples
    #
    #   class ProductSearch < Lupa::Search
    #
    #     class Scope
    #
    #       def category
    #         scope.where(category: search_attributes[:category])
    #       end
    #
    #     end
    #
    #     def initialize(scope = Product.in_stock)
    #       @scope = scope
    #     end
    #
    #   end
    #
    #   search = ProductSearch.search({ category: 'furniture' }).first
    #   # => #<Product:0x007f9c0ce1b1a8>
    #
    # Returns the search result.
    def method_missing(method_sym, *arguments, &block)
      if results.respond_to?(method_sym)
        results.send(method_sym, *arguments, &block)
      else
        raise Lupa::ResultMethodNotImplementedError, "The resulting scope does not respond to #{method_sym} method."
      end
    end

    private
      # Internal: Store the scope class.
      #
      # Stores the scope class.
      attr_accessor :scope_class

      # Internal: Set @search_attributes by merging default search attributes with the ones passed to search method.
      #
      # === Options
      #
      # <tt>attributes</tt> - The hash containing the search attributes.
      #
      # === Examples
      #
      #   class ProductSearch < Lupa::Search
      #
      #     class Scope
      #
      #       def category
      #         scope.where(category: search_attributes[:category])
      #       end
      #
      #       def in_stock
      #         scope.where(in_stock: search_attributes[:in_stock])
      #       end
      #
      #     end
      #
      #     def default_search_attributes
      #       { in_stock: true }
      #     end
      #
      #   scope  = Product.where(in_warehouse: true)
      #   search = ProductSearch.new(scope).search(category: 'furniture')
      #
      #   set_search_attributes(category: 'furniture')
      #   # => { category: 'furniture', in_stock: true }
      #
      # Sets @search_attributes by merging default search attributes with the ones passed to search method.
      def set_search_attributes(attributes)
        attributes = merge_search_attributes(attributes)
        attributes = symbolize_keys(attributes)
        attributes = remove_blank_attributes(attributes)

        @search_attributes = attributes
      end

      # Internal: Merge search attributes with default search attributes
      def merge_search_attributes(attributes)
        return default_search_attributes.merge(attributes) if default_search_attributes.kind_of?(Hash)

        raise Lupa::DefaultSearchAttributesError, "default_search_attributes doesn't return a Hash."
      end

      # Internal: Symbolizes all keys passed to the search attributes.
      def symbolize_keys(attributes)
        return attributes.reduce({}) do |attribute, (key, value)|
          attribute.tap { |a| a[key.to_sym] = symbolize_keys(value) }
        end if attributes.is_a? Hash

        return attributes.reduce([]) do |attribute, value|
          attribute << symbolize_keys(value); attribute
        end if attributes.is_a? Array

        attributes
      end

      # Internal: Removes all empty values passed to search attributes.
      def remove_blank_attributes(attributes)
        attributes.delete_if { |key, value| clean_attribute(value) }
      end

      # Internal: Iterates over value child attributes to remove empty values.
      def clean_attribute(value)
        if value.kind_of?(Hash)
          value.delete_if { |key, value| clean_attribute(value) }.empty?
        elsif value.kind_of?(Array)
          value.delete_if { |value| clean_attribute(value) }.empty?
        else
          value.to_s.strip.empty?
        end
      end

      # Internal: Includes ScopeMethods module into the Scope class and instantiate it.
      def set_scope_class
        klass = self.class::Scope
        klass.send(:include, ScopeMethods)
        @scope_class = klass.new(@scope, @search_attributes)
      end

      # Internal: Check for search methods to be correctly defined using search attributes.
      #
      # * If you pass a search attribute that doesn't exist and your Scope class
      #   doesn't have that method defined a Lupa::ScopeMethodNotImplementedError
      #   exception will be raised.
      def check_method_definitions
        method_names = search_attributes.keys

        method_names.each do |method_name|
          next if scope_class.respond_to?(method_name)
          raise Lupa::ScopeMethodNotImplementedError, "#{method_name} is not defined on your #{self.class}::Scope class."
        end
      end

      # Internal: Applies search attributes keys as methods over the scope_class.
      #
      # * If search_attributes are not specified a Lupa::SearchAttributesError
      #   exception will be raised.
      #
      # Returns the result of the search.
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
