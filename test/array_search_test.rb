require 'test_helper'

class ArraySearch < Lupa::Search
  class Scope
    def even_numbers
      if search_attributes[:even_numbers]
        scope.collect { |number| number if number.even? }.compact
      else
        scope
      end
    end

    def reverse
      if search_attributes[:reverse]
        scope.reverse
      else
        scope
      end
    end
  end
end

describe Lupa::Search do
  before do
    @array = [1, 2, 3, 4, 5, 6, 7, 8]
    @search_attributes = { even_numbers: true }
  end

  describe '#search_attributes' do
    context 'when passing search params' do
      it 'returns search attributes' do
        search = ArraySearch.new(@array).search(@search_attributes)
        search.search_attributes.must_equal @search_attributes
      end
    end

    context 'when not passing search params' do
      it 'returns nil' do
        search = ArraySearch.new(@array)
        search.search_attributes.must_equal nil
      end
    end

    context 'when passing an empty hash to search params' do
      it 'returns an empty hash' do
        params = {}
        search = ArraySearch.new(@array).search(params)
        search.search_attributes.must_equal params
      end
    end

    context 'when passing search params with empty values' do
      it 'removes empty values from the search params' do
        params = { even_numbers: true, reverse: { one: '', two: '' }, blank: { an_array: [''] }}
        search = ArraySearch.new(@array).search(params)
        search.search_attributes.must_equal @search_attributes
      end
    end

    context 'when search params contains keys as strings' do
      it 'converts the strings into symbols' do
        params = { 'even_numbers' => true, reverse: { one: '', two: '' }, blank: { an_array: [''] }}
        search = ArraySearch.new(@array).search(params)
        search.search_attributes.must_equal @search_attributes
      end
    end

    context 'when passing another object rather than a hash to search params' do
      it 'raises a Lupa::SearchAttributesError' do
        proc { ArraySearch.new(@array).search(1) }.must_raise Lupa::SearchAttributesError
      end
    end
  end

  describe '#search' do
    context 'when passing valid params' do
      it 'sets search attributes' do
        search = ArraySearch.new(@array).search(@search_attributes)
        search.search_attributes.must_equal @search_attributes
      end
    end

    context 'when passing invalid params' do
      it 'raises a Lupa::ScopeMethodNotImplementedError' do
        params = { even_numbers: true, not_existing_search: 2 }
        proc { ArraySearch.new(@array).search(params) }.must_raise Lupa::ScopeMethodNotImplementedError
      end
    end
  end

  describe '#results' do
    context 'when passing search attributes' do
      it 'returns the search results' do
        search = ArraySearch.new(@array).search(@search_attributes)
        search.results.must_equal [2, 4, 6, 8]
      end
    end

    context 'when not passing search attributes' do
      it 'returns the default scope' do
        search = ArraySearch.new(@array)
        proc { search.results }.must_raise Lupa::SearchAttributesError
      end
    end

    context 'when passing multiple search attributes' do
      it 'returns the search results' do
        params = { even_numbers: true, reverse: true }
        search = ArraySearch.new(@array).search(params)
        search.results.must_equal [8, 6, 4, 2]
      end
    end
  end

  describe '#method_missing' do
    context 'when result respond to method' do
      it 'applies method to the resulting scope' do
        search = ArraySearch.new(@array).search(@search_attributes)
        search.first.must_equal 2
      end
    end

    context 'when result not respond to method' do
      it 'raises a Lupa::ResultMethodNotImplementedError exception' do
        search = ArraySearch.new(@array).search(@search_attributes)
        proc { search.not_existing_method }.must_raise Lupa::ResultMethodNotImplementedError
      end
    end
  end

end
