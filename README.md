![](lupa.png)

Lupa means *Magnifier* in spanish.

[![Build Status](https://travis-ci.org/edelpero/lupa.svg?branch=master)](https://travis-ci.org/edelpero/lupa) [![Coverage Status](https://coveralls.io/repos/edelpero/lupa/badge.svg?branch=master)](https://coveralls.io/r/edelpero/lupa?branch=master) [![Code Climate](https://codeclimate.com/github/edelpero/lupa/badges/gpa.svg)](https://codeclimate.com/github/edelpero/lupa) [![Inline docs](http://inch-ci.org/github/edelpero/lupa.svg?branch=master)](http://inch-ci.org/github/edelpero/lupa)

Lupa lets you create simple, robust and scaleable search filters with ease using regular Ruby classes and object oriented design patterns.

Lupa is Framework and ORM agnostic. It will work with any ORM or Object that can build a query using **chained method calls**, like ActiveRecord: `
Product.where(name: 'Digital').where(category: '23').limit(2)`.

**Table of Contents:**

* [Search Class](#search-class)
    * [Overview](#overview)
    * [Definition](#definition)
    * [Public Methods](#public-methods)
    * [Default Search Scope](#default-search-scope)
    * [Default Search Attributes](#default-search-attributes)
    * [Combining Search Classes](#combining-search-classes)
* [Usage with Rails](#usage-with-rails)
* [Testing](#testing)
    * [Testing Default Scope](#testing-default-scope)
    * [Testing Default Search Attributes](#testing-default-search-attributes)
    * [Testing Each Scope Method Individually](#testing-each-scope-method-individually)
* [Benchmarks](#benchmarks)
    * [Lupa vs HasScope](#lupa-vs-hasscope)
    * [Lupa vs Searchlight](#lupa-vs-searchlight)
* [Installation](#installation)


## Search Class

### Overview

```ruby
products = ProductSearch.new(current_user.products).search(name: 'digital', category: '23')

# Iterate over the search results
products.each do |product|
  # Your logic goes here
end
```
Calling **.each** on the instance will build a search by chaining calls to **name** and **category** methods defined in our **ProductSearch::Scope** class.

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  # Scope class holds all your search methods.
  class Scope

    # Search method
    def name
      scope.where('name iLIKE ?', "%#{search_attributes[:name]}%")
    end

    # Search method
    def category
      scope.where(category_id: search_attributes[:category])
    end

  end
end
```

### Definition
To define a search class, your class must inherit from **Lupa::Search** and you must define a **Scope** class inside your search class.

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  class Scope
  end
end
```
Inside your **Scope** class you must define your scope methods. You'll also be able to access to the following methods inside your scope class: **scope** and **search_attributes**.

* **`scope:`** returns the current scope when the scope method is called.
* **`search_attributes:`** returns a hash containing the all search attributes specified including the default ones.

<u>**Note:**</u> All keys of **`search_attributes`** are symbolized.

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  # Scope class holds all your search methods.
  class Scope

    # Search method
    def name
      scope.where('name LIKE ?', "%#{search_attributes[:name]}%")
    end

    # Search method
    def category
      scope.where(category_id: search_attributes[:category])
    end

  end
end
```
The scope methods specified on the search params will be the only ones applied to the scope. Search params keys must always match the Scope class methods names.

### Public Methods

Your search class has the following public methods:

- **`scope:`** returns the scope to which all search rules will be applied.

```ruby
search = ProductSearch.new(current_user.products).search(name: 'chair', category: '23')
search.scope

# => current_user.products
```

- **`search_attributes:`** returns a hash with all search attributes including default search attributes.

```ruby
search = ProductSearch.new(current_user.products).search(name: 'chair', category: '23')
search.search_attributes

# => { name: 'chair', category: '23' }
```
- **`default_search_attributes:`** returns a hash with default search attributes. A more detailed explanation about default search attributes can be found below this section.

- **`results:`** returns the resulting scope after all searching rules have been applied.

```ruby
search = ProductSearch.new(current_user.products).search(name: 'chair', category: '23')
search.results

# => #<Product::ActiveRecord_Relation:0x007ffda11b7d48>
```

- **OTHER METHODS** applied to your search class will result in calling to **`results`** and applying that method to the resulting scope. If the resulting scope doesn't respond to the method, an exception will be raised.

```ruby
search = ProductSearch.new(current_user.products).search(name: 'chair', category: '23')

search.first
# => #<Product id: 1, name: 'Eames Chair', category_id: 23, created_at: "2015-04-06 18:54:13", updated_at: "2015-04-06 18:54:13" >

search.unexisting_method
# => Lupa::ResultMethodNotImplementedError: The resulting scope does not respond to unexisting_method method.
```

### Default Search Scope

You can define a default search scope if you want to use a search class with an specific resource by overriding the initialize method as follows:

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  class Scope
    ...
  end

  # Be careful not to change the scope variable name,
  # otherwise you will experience issues.
  def initialize(scope = Product.all)
    @scope = scope
  end
end
```

Then you can use your search class without passing the scope:

```ruby
search = ProductSearch.search(name: 'chair', category: '23')

search.first
# => #<Product id: 1, name: 'Eames Chair', category_id: 23, created_at: "2015-04-06 18:54:13", updated_at: "2015-04-06 18:54:13" >
```

### Default Search Attributes

Defining default search attributes will cause the scope method to be invoked always.

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  class Scope
    ...
  end

  # This should always return a hash
  def default_search_attributes
    { category: '23' }
  end
end
```

```ruby
search = ProductSearch.new(current_user.products).search(name: 'chair')

search.search_attributes
# => { name: 'chair', category: '23' }
```

**<u>Note:</u>** You can override default search attributes by passing it to the search params.

``` ruby
search = ProductSearch.new(current_user.products).search(name: 'chair', category: '42')

search.search_attributes
# => { name: 'chair', category: '42' }
```

### Combining Search Classes

You can reuse your search class in order to keep them DRY.

A common example is searching records created between two dates. So lets create a **CreatedAtSearch** class to handle that logic.

```ruby
# app/searches/created_between_search.rb

class CreatedAtSearch < Lupa::Search
  class Scope

    def created_before
      ...
    end

    def created_after
      ...
    end

    def created_between
      if created_start_date && created_end_date
        scope.where(created_at: created_start_date..created_end_date)
      end
    end

    private

      # Parses search_attributes[:created_between][:start_date]
      def created_start_date
        search_attributes[:created_between] &&
        search_attributes[:created_between][:start_date].try(:to_date)
      end

      # Parses search_attributes[:created_between][:end_date]
      def created_end_date
        search_attributes[:created_between] &&
        search_attributes[:created_between][:end_date].try(:to_date)
      end
  end
end
```

Now we can use it in our **ProductSearch** class:

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  class Scope

    def name
      ...
    end

    # We use CreatedAtSearch class to perform the search.
    # Be sure to always call `results` method on your composed
    # search class.
    def created_between
      CreatedAtSearch.new(scope).
        search(created_between: search_attributes[:created_between]).
        results
    end

    def category
      ...
    end

  end
end
```
**Note:** If you are combining search classes. Be sure to always call **results** method on the search classes composing your main search class.

## Usage with Rails

### Forms

Define a custom form:

```haml
# app/views/products/_search.html.haml

= form_tag products_path, method: :get do
  = text_field_tag 'name'
  = select_tag 'category', options_from_collection_for_select(@categories, 'id', 'name')
  = date_field_tag 'created_between[start_date]'
  = date_field_tag 'created_between[end_date]'
  = submit_tag :search
```

### Controllers

Create a new instance of your search class and pass a collection to which all search conditions will be applied and specify the search params you want to apply:

```ruby
# app/controllers/products_controller.rb

class ProductsController < ApplicationController
  def index
    @products = ProductSearch.new(current_user.products).search(search_params)
  end

  protected
    def search_params
      params.permit(:name, :category, created_between: [:start_date, :end_date])
    end
end
```
### Views

Loop through the search results on your view.

```haml
# app/views/products/index.html.haml

%h1 Products

%ul
  - @products.each do |product|
    %li
      = "#{product.name} - #{product.price} - #{product.category}"
```

## Testing

This is a list of things you should test when creating a search class:

- **Default Scope** if specified.
- **Default Search Attributes** if specified.
- **Each Scope Method** individually.

### Testing Default Scope

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  class Scope
    ...
  end

  def initialize(scope = Product.all)
    @scope = scope
  end
end
```

```ruby
# test/searches/product_search_test.rb
require 'test_helper'

describe ProductSearch do
  describe 'Default Scope' do
    context 'when not passing a scope to search initializer and no search params' do
      it 'returns default scope' do
        results = ProductSearch.search({}).results
        results.must_equal Product.all
      end
    end
  end
end
```

### Testing Default Search Attributes

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  class Scope
    ...
  end

  def initialize(scope = Product.all)
    @scope = scope
  end

  def default_search_attributes
    { category: '23' }
  end
end
```

```ruby
# test/searches/product_search_test.rb
require 'test_helper'

describe ProductSearch do
  describe 'Default Search Attributes' do
    context 'when not overriding default_search_attributes' do
      it 'returns default default_search_attributes' do
        default_search_attributes = { category: 23 }
        search = ProductSearch.search({})
        search.default_search_attributes.must_equal default_search_attributes
      end
    end
  end
end
```

### Testing Each Scope Method Individually

```ruby
# app/searches/product_search.rb

class ProductSearch < Lupa::Search
  class Scope
    def category
      scope.where(category_id: search_attributes[:category])
    end

    def name
      ...
    end
  end

  def initialize(scope = Product.all)
    @scope = scope
  end
end
```

```ruby
# test/searches/product_search_test.rb

require 'test_helper'

describe ProductSearch do
  describe 'Scopes' do

    describe '#category' do
      it 'returns products from specified category' do
        results = ProductSearch.search(category: '23').results
        results.must_equal Product.where(category_id: '23')
      end
    end

    describe '#name' do
      it 'returns products that contain specified letters' do
        ...
      end
    end

  end
end
```

## Benchmarks

I used [benchmark-ips](https://github.com/evanphx/benchmark-ips).

### Lupa vs. [HasScope](https://github.com/plataformatec/has_scope)

```
Calculating -------------------------------------
                lupa   265.000  i/100ms
           has_scope   254.000  i/100ms
-------------------------------------------------
                lupa      3.526k (±24.7%) i/s -     67.045k
           has_scope      3.252k (±24.8%) i/s -     61.976k

Comparison:
                lupa:     3525.8 i/s
           has_scope:     3252.0 i/s - 1.08x slower
```

### Lupa vs. [Searchlight](https://github.com/nathanl/searchlight)

```
Calculating -------------------------------------
                lupa   480.000  i/100ms
         searchlight   232.000  i/100ms
-------------------------------------------------
                lupa      7.273k (±25.1%) i/s -    689.280k
         searchlight      2.665k (±14.1%) i/s -    260.072k

Comparison:
                lupa:     7273.5 i/s
         searchlight:     2665.4 i/s - 2.73x slower
```

*If you know about another gem that was not included on the benchmark, feel free to run the benchmarks and send a Pull Request.*

## Installation

Add this line to your application's Gemfile:

    gem 'lupa'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lupa


## Contributing

1. Fork it ( https://github.com/edelpero/lupa/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
