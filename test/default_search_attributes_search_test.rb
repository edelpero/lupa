require 'test_helper'

class ClassWithDefaultSearchAttributesSearch < Lupa::Search

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

  def default_search_attributes
    { reverse: true }
  end

end

class ClassWithoutDefaultSearchAttributesSearch < Lupa::Search

  class Scope
    def reverse; end
  end

  def initialize(scope = [1, 2, 3, 4])
    @scope = scope
  end

end

class ClassWithInvalidDefaultSearchAttributesSearch < Lupa::Search

  class Scope
    def reverse; end
  end

  def initialize(scope = [1, 2, 3, 4])
    @scope = scope
  end

  def default_search_attributes
    1
  end

end


describe Lupa::Search do
  before do
    @default_search_attributes = { reverse: true }
  end

  describe '#default_search_attributes' do
    context 'when class has a default search attributes' do
      it 'returns a hash containing default search attributes' do
        search = ClassWithDefaultSearchAttributesSearch.search({})
        search.default_search_attributes.must_equal @default_search_attributes
      end
    end

    context 'when overriding default search attributes' do
      it 'returns a hash with the default search attribute overwritten' do
        params = { reverse: false }
        search = ClassWithDefaultSearchAttributesSearch.search(params)
        search.search_attributes.must_equal params
      end
    end

    context 'when class does not have default search attributes' do
      it 'returns an empty hash' do
        params = {}
        search = ClassWithoutDefaultSearchAttributesSearch.search({})
        search.default_search_attributes.must_equal params
      end
    end

    context 'when default_search_attributes does not return a Hash' do
      it 'raises a Lupa::DefaultSearchAttributesError exception' do
        proc { ClassWithInvalidDefaultSearchAttributesSearch.search({}).results }.must_raise Lupa::DefaultSearchAttributesError
      end
    end
  end

  describe '#results' do
    context 'when class has a default search attributes' do
      it 'applies default search methods to scope' do
        results = ClassWithDefaultSearchAttributesSearch.search({}).results
        results.must_equal [4, 3, 2, 1]
      end
    end

    context 'when class does not have default search attributes' do
      it 'does not applies default search methods to scope' do
        results = ClassWithoutDefaultSearchAttributesSearch.search({}).results
        results.must_equal [1, 2, 3, 4]
      end
    end
  end
end
