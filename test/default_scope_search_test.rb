require 'test_helper'

class ClassWithDefaultScopeSearch < Lupa::Search

  class Scope
    def reverse
      if search_attributes[:reverse]
        scope.reverse
      end
    end
  end

  def initialize(scope = [1, 2, 3, 4])
    @scope = scope
  end

end

class ClassWithoutDefaultScopeSearch < Lupa::Search

  class Scope
    def reverse; end
  end

end


describe Lupa::Search do
  before do
    @array = [1, 2, 3, 4]
    @search_attributes = { reverse: true }
  end

  describe '.search' do
    context 'when class has a default scope' do
      context 'when passing search params' do
        it 'creates an instance of it class' do
          results = ClassWithDefaultScopeSearch.search(@search_attributes).results
          results.must_equal [4, 3, 2, 1]
        end
      end

      context 'when not passing search params' do
        it 'returns the default scope' do
          results = ClassWithDefaultScopeSearch.search({}).results
          results.must_equal [1, 2, 3, 4]
        end
      end
    end

    context 'when class does not have a default scope' do
      it 'raises a Lupa::DefaultScopeError exception' do
        proc { ClassWithoutDefaultScopeSearch.search(@search_attributes) }.must_raise Lupa::DefaultScopeError
      end
    end
  end
end
