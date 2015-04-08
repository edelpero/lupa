require 'test_helper'

class ReverseSearch < Lupa::Search

  class Scope
    def reverse
      scope.reverse
    end
  end

end

class EvenSearch < Lupa::Search

  class Scope
    def even
      scope.map { |number| number if number.even? }.compact
    end

    def reverse
      ReverseSearch.new(scope).search(reverse: true)
    end
  end

  def initialize(scope = [1, 2, 3, 4])
    @scope = scope
  end

end


describe Lupa::Search do

  describe 'Composition' do
    it 'calls another search class inside of it' do
      results = EvenSearch.search(even: true, reverse: true).results
      results.first.must_equal 4
    end
  end

end
