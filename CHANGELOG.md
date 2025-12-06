## 1.0.2

* documentation
    * Add comprehensive RDoc documentation for all classes and methods
    * Include detailed examples and usage patterns in RDoc
    * Document all error classes with practical examples
    * Fix multiple typos in README.md
    * Update Table of Contents links in README.md
    * Add benchmarks section comparing Lupa with HasScope and Searchlight
    * Improve code examples and usage patterns in README.md

* ci
    * Migrate from Travis CI to GitHub Actions
    * Add support for Ruby 2.2 through 3.3
    * Configure Coveralls for Ruby 2.5+ (conditional loading for compatibility)

* dependencies
    * Update minitest development dependency from ~> 5.5.1 to ~> 5.5
    * Update bundler development dependency from ~> 1.6 to >= 1.6
    * Add rake development dependency >= 10.0

## 1.0.1

* enhancements
    * A **Lupa::DefaultSearchAttributesError** exception will be raised if `default_search_attributes` does not return a hash.