require 'savon'
require 'pp'
require 'im_helpers/territories'

module HubDilicom

  # erreurs
  class Error < StandardError
  end

  class Warning < StandardError
  end

  class OrderDuplicatedError < StandardError
  end

  class OrderNotFoundError < StandardError
  end

  class UnknownGlnError < StandardError
  end

  class EanNotFoundError < StandardError
  end

  class EanNotAvailableError < StandardError
  end

  class PlatformAccessDeniedError < StandardError
  end

  class AuthenticationError < StandardError
  end

  class InvalidArgumentsError < StandardError
  end


  class Book
    attr_accessor :ean13, :gln_distributor, :price, :currency, :onix, :available, :message

    def initialize(ean13, gln_distributor, price=nil, currency="EUR")
      @ean13=ean13
      @gln_distributor=gln_distributor
      @price=price
      @currency=currency
    end

    def to_hash(keys)
      {:ean13 => @ean13, :gln_distributor => @gln_distributor, :unit_price => @price, :currency=>@currency}.delete_if { |k, v| not v }.select { |k, v| keys.include?(k) }
    end
  end

  class Books
    attr_accessor :books, :books_hash

    def initialize(books)
      @books=[]
      @books_hash={}
      books.each do |book|
        self.add_book(book)
      end
    end

    def add_book(book)
      @books << book
      @books_hash[[book.ean13, book.gln_distributor]]=book
    end

    def get_book(ean13, gln_distributor)
      @books_hash[[ean13, gln_distributor]]
    end

    def to_hash(keys)
      @books.map do |book|
        book.to_hash(keys)
      end
    end

    def each &block
      @books.each do |book|
        block.call(book)
      end
    end
  end

  class Link
    attr_accessor :url, :format, :mimetype, :ean13

    def initialize(url, format, mimetype, ean13)
      @url=url
      @format=format
      @mimetype=mimetype
      @ean13=ean13
    end
  end

  class OrderLine
    attr_accessor :book, :quantity, :reference, :identifier, :links, :unit_price_excluding_tax, :special_code

    def initialize(book, quantity=1, reference=nil, special_code=nil)
      @reference=reference
      @book=book
      @quantity=quantity
      @links=[]
      @special_code=special_code
    end

    def to_hash(keys)
      book.to_hash([:ean13, :gln_distributor, :unit_price]).merge({:unit_price_excluding_tax=>0}).merge(book.to_hash([ :currency])).merge({  :special_code=>@special_code,:quantity => @quantity, :line_reference => @reference}.delete_if { |k, v| not v }.select { |k, v| keys.include?(k) })
    end

  end

  class Order
    attr_accessor :identifier, :lines, :lines_hash

    def initialize(identifier, lines=[])
      @identifier=identifier
      @lines=[]
      @lines_hash={}
      lines.each do |line|
        self.add_line(line)
      end
    end

    def add_line(line)
      unless @lines.include?(line)
        @lines << line
      end
      @lines_hash[[line.book.ean13, line.book.gln_distributor]]=line
    end

    def get_line(ean13, gln_distributor)
      @lines_hash[[ean13, gln_distributor]]
    end

    def to_hash(keys)
      olh=@lines.map { |line| line.to_hash([:quantity]) }
      {:order_id => @identifier, :order_line => olh, :order_request_line => olh}.delete_if { |k, v| not v }.select { |k, v| keys.include?(k) }
    end

  end

  class Customer
    attr_accessor :identifier, :civility, :first_name, :last_name, :email, :country, :postal_code, :city

    def initialize(identifier, last_name, country, postal_code=" ", city=" ", civility=nil, first_name=nil, email=nil)
      @identifier=identifier
      @last_name=last_name
      @country=country
      @postal_code=postal_code
      @city=city
      @civility=civility
      @first_name=first_name
      @email=email
    end

    def to_hash
      {:identifier => @identifier, :civility => @civility, :first_name => @first_name, :last_name => @last_name, :email => @email, :country => @country, :postal_code => @postal_code, :city => @city}.delete_if { |k, v| not v }
    end
  end


  class Client
    attr_accessor :client

    # Initialisation du client prenant comme argument le glnReseller et le passwordReseller
    def initialize(gln, password, test=false)
      if test
        @wsdl="https://hub-test.centprod.com/v3/hub-numerique/hub-numerique-services.wsdl"
      else
        @wsdl="https://hub-dilicom.centprod.com/v3/hub-numerique/hub-numerique-services.wsdl"
      end

      @glnReseller=gln
      @passwordReseller=password

      @glnContractor=gln
      @glnDelivery=gln

      savon_options={:wsdl => @wsdl,
                     :open_timeout=> 3600,
                     :read_timeout=> 3600,
                     :log=>test}
      if test
        savon_options[:ssl_verify_mode]=:none
      end
      @client=Savon.client(savon_options)
    end

    def set_contractor_gln(gln)
      @glnContractor=gln
    end

    def set_delivery_gln(gln)
      @glnDelivery=gln
    end

    def calculated_unit_price_excl_tax(price,country)
      tax=ImHelpers::Territories.country_ebook_vat(country)
      tax_coef=("%.#{3}f" % (100.0/(tax+100.0))).to_f
      price_excl_tax=(price*tax_coef).round
      price_excl_tax
    end

    # Récupération de l'URL du flux ONIX depuis la date since
    def get_full_onix_url(since)
      since_str=since.strftime("%Y-%m-%dT%H:%M:%S")
      response=@client.call(:get_notices, message_with_auth({:glnContractor=>@glnContractor}.merge(:sinceDate => since_str)))
      message=response.body[:get_notices_response][:onix_file_url]
      if message
        message[:http_link]
      else
        nil
      end
    end

    require 'open-uri'

    # Récupération du flux ONIX dans un File
    def get_full_onix_tempfile(since)
      url=self.get_full_onix_url(since)
      if url
        open(url)
      end
    end

    # Récupération de l'ONIX du livre en argument
    def get_book_onix(book)
      self.get_books_onix(Books.new([book]))
      book
    end

    # Récupération de l'ONIX des livres en argument
    def get_books_onix(books)
      response=@client.call(:get_detail_notices, message_with_auth({:glnContractor=>@glnContractor}.merge(:notice => books.to_hash([:ean13, :gln_distributor]))))
      message=response.body[:get_detail_notices_response][:detail_notice]
      if message
        case message
          when Array
            message.each do |rbook|
              b=books.get_book(rbook[:ean13], rbook[:gln_distributor])
              b.onix=rbook[:onix_product]
            end
          else
            b=books.get_book(message[:ean13], message[:gln_distributor])
            b.onix=message[:onix_product]
        end
        books
      else
        nil
      end
    end

    # Vérification de la disponibilité du livre en argument
    def get_book_availability(book,country="FR")
      self.get_books_availability(Books.new([book]),country)
      book
    end

    # Vérification de la disponibilité des livres en argument
    def get_books_availability(books,country="FR")
      books_h=books.to_hash([:ean13, :gln_distributor, :unit_price])
      books_h.each do |book|
        book[:unit_price_excluding_tax]=calculated_unit_price_excl_tax(book[:unit_price],country)
      end
      response=@client.call(:check_availability, message_with_auth({:glnContractor=>@glnContractor}.merge({:country=>country}).merge({:check_availability_line => books_h})))
      message=response.body[:check_availability_response][:check_availability_response_line]
      if message
        case message
          when Array
            message.each do |rline|
              b=books.get_book(rline[:ean13], rline[:gln_distributor])
              b.available=rline[:check_availability_return_value]=="AVAILABLE" ? true : false
              b.message=rline[:return_message]
            end
          else
            b=books.get_book(message[:ean13], message[:gln_distributor])
            b.available=message[:check_availability_return_value]=="AVAILABLE" ? true : false
            b.message=message[:return_message]
        end
        books
      else
        nil
      end
    end

    # Passage d'une commande
    def send_order(order, customer, book_owner=nil)
      unless book_owner
        book_owner=customer
      end
      order_line_h=order.to_hash([:order_request_line])
      pp order_line_h
      order_line_h[:order_request_line].each do |line|
        line[:unit_price_excluding_tax]=calculated_unit_price_excl_tax(line[:unit_price],customer.country)
      end

      response=@client.call(:send_order, message_with_auth(order.to_hash([:order_id]).merge({:glnContractor=>@glnContractor,:glnDelivery=>@glnDelivery}).merge({:customer_id => customer.identifier}.merge(:final_book_owner => book_owner.to_hash).merge(order_line_h))))
      message=response.body[:send_order_response][:order_line]
      if message
        case message
          when Array
            message.each do |m|
              message_to_order_line(order, m)
            end
          else
            message_to_order_line(order, message)
        end
      else
        raise_error(response.body[:send_order_response])
      end
    end

    # Récupération d'une commande
    def get_order(order)
      response=@client.call(:get_order_detail, message_with_auth({:glnContractor=>@glnContractor}.merge(order.to_hash([:order_id]))))
      message=response.body[:get_order_detail_response][:order_line]
      if message
        case message
          when Array
            message.each do |m|
              message_to_order_line(order, m)
            end
          else
            message_to_order_line(order, message)
        end
        order
      else
        raise_error(response.body[:get_order_detail_response])
      end
    end

    private
    def message_with_auth(attrs)
      {:message => {:glnReseller => @glnReseller, :passwordReseller => @passwordReseller}.merge(attrs.delete_if { |k, v| not v })}
    end

    def raise_error_message(message)
      error=message[:return_status]
      case error
        when "ERROR"
          raise Error, message[:return_message]
        when "INVALID_ARGUMENTS"
          raise InvalidArgumentsError, message[:return_message]
        when "DUPLICATED"
          raise OrderDuplicatedError, message[:return_message]
        when "ORDERID_NOT_FOUND"
          raise OrderNotFoundError, message[:return_message]
        when "WARNING"
          raise Warning, message[:return_message]
        when "UNKNOWN_GLN"
          raise UnknownGlnError, message[:return_message]
        when "EAN_NOT_FOUND"
          raise EanNotFoundError, message[:return_message]
        when "EAN_NOT_AVAILABLE"
          raise EanNotAvailableError, message[:return_message]
        when "PLATFORM_ACCES_DENIED"
          raise PlatformAccessDeniedError, message[:return_message]
        when "AUTHENTICATION_ERROR"
          raise AuthenticationError, message[:return_message]
      end

    end

    def raise_error(message)
      case message
        when Array
          message.each do |e|
            raise_error_message(e)
          end
        else
          raise_error_message(message)
      end
    end

    def message_to_link(order_line, message)
      lnk=Link.new(message[:url], message[:format], message[:mimetype], message[:ean13])
      order_line.links << lnk
    end

    def message_to_order_line(order, message)
      order_line=order.get_line(message[:ean13], message[:gln_distributor])
      unless order_line
        order_line=OrderLine.new(Book.new(message[:ean13], message[:gln_distributor]))
      end
      order_line.identifier=message[:order_line_id]
      order_line.reference=message[:line_reference]
      link_message=message[:link]
      if link_message
        case link_message
          when Array
            link_message.each do |m|
              message_to_link(order_line, m)
            end
          else
            message_to_link(order_line, link_message)
        end
      else
        raise_error(message)
      end
      order.add_line(order_line)

    end

  end
end
