module HubDilicom
  class OrderLine
    attr_accessor :book, :quantity, :reference, :identifier, :links, :unit_price_excluding_tax, :special_code

    def initialize(book, quantity = 1, reference = nil, special_code = nil)
      @reference = reference
      @book = book
      @quantity = quantity
      @links = []
      @special_code = special_code
    end

    def to_hash(keys)
      book.to_hash([:ean13, :gln_distributor, :unit_price]).
        merge({ unit_price_excluding_tax: 0 }).
        merge(book.to_hash([:currency])).
        merge({ special_code: @special_code, quantity: @quantity, line_reference: @reference }.delete_if { |k, v| not v }.select { |k, v| keys.include?(k) })
    end

  end
end
