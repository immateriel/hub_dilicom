module HubDilicom
  class Book
    attr_accessor :ean13, :gln_distributor, :price, :currency, :onix, :available, :message

    def initialize(ean13, gln_distributor, price = nil, currency = "EUR")
      @ean13 = ean13
      @gln_distributor = gln_distributor
      @price = price
      @currency = currency
    end

    def to_hash(keys)
      { ean13: @ean13, gln_distributor: @gln_distributor, unit_price: @price, unit_price_excluding_tax: 0, currency: @currency }.delete_if { |k, v| not v }.select { |k, v| keys.include?(k) }
    end
  end
end
