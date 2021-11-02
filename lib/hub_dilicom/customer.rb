module HubDilicom
  class Customer
    attr_accessor :identifier, :civility, :first_name, :last_name, :email, :country, :postal_code, :city

    def initialize(identifier, last_name, country, postal_code = " ", city = " ", civility = nil, first_name = nil, email = nil)
      @identifier = identifier
      @last_name = last_name
      @country = country
      @postal_code = postal_code
      @city = city
      @civility = civility
      @first_name = first_name
      @email = email
    end

    def to_hash
      { identifier: @identifier, civility: @civility, first_name: @first_name, last_name: @last_name,
        email: @email, country: @country, postal_code: @postal_code, city: @city }.delete_if { |k, v| not v }
    end
  end
end
