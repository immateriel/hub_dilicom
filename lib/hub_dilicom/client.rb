require 'open-uri'
require 'savon'

module HubDilicom
  class Client
    attr_accessor :client, :calculate_unit_price_excl_tax

    # Initialisation du client prenant comme argument le glnReseller et le passwordReseller
    def initialize(gln, password, test = false, debug = false)
      if test
        @wsdl = "https://hub-test.centprod.com/v3/hub-numerique/hub-numerique-services.wsdl"
      else
        @wsdl = "https://hub-dilicom.centprod.com/v3/hub-numerique/hub-numerique-services.wsdl"
      end

      @glnReseller = gln
      @passwordReseller = password

      @glnContractor = nil
      @glnDelivery = nil

      savon_options = { wsdl: @wsdl,
                        open_timeout: 3600,
                        read_timeout: 3600,
                        log: debug }
      if test
        savon_options[:ssl_verify_mode] = :none
      end
      @client = Savon.client(savon_options)
    end

    def set_contractor_gln(gln)
      @glnContractor = gln
    end

    def set_delivery_gln(gln)
      @glnDelivery = gln
    end

    def define_calculate_unit_price_excl_tax &block
      @calculate_unit_price_excl_tax = block
    end

    def calculated_unit_price_excl_tax(price, country)
      if @calculate_unit_price_excl_tax
        @calculate_unit_price_excl_tax.call price, country
      else
        if country == "FR"
          # taux fixe 5.5 FR
          tax_coef = ("%.#{3}f" % (100.0 / (5.5 + 100.0))).to_f
          price_excl_tax = (price * tax_coef).round
          price_excl_tax
        else
          raise UndefinedCalculateUnitPrice, "calculate_unit_price_excl_tax must be defined for countries other than FR"
        end
      end
    end

    # Récupération de l'URL du flux ONIX depuis la date since
    # @param [Time] since récupération depuis cette date
    # @return [String, nil] URL vers le ONIX
    def get_full_onix_url(since)
      since_str = since.strftime("%Y-%m-%dT%H:%M:%S")
      response = @client.call(:get_notices, message_with_auth({ glnContractor: @glnContractor }.merge(sinceDate: since_str)))
      message = response.body[:get_notices_response][:onix_file_url]
      if message
        message[:http_link]
      else
        nil
      end
    end

    # Récupération du flux ONIX dans un File
    # @param [Time] since récupération depuis cette date
    # @return [IO, nil] données ONIX
    def get_full_onix_tempfile(since)
      url = self.get_full_onix_url(since)
      if url
        open(url)
      end
    end

    # Récupération de l'ONIX du livre en argument
    # @param [Book] book
    # @return [Book]
    def get_book_onix(book)
      self.get_books_onix(Books.new([book]))
      book
    end

    # Récupération de l'ONIX des livres en argument
    # @param [Books] books
    # @return [Books, nil]
    def get_books_onix(books)
      response = @client.call(:get_detail_notices, message_with_auth({ glnContractor: @glnContractor }.merge(notice: books.to_hash([:ean13, :gln_distributor]))))
      message = response.body[:get_detail_notices_response][:detail_notice]
      if message
        case message
        when Array
          message.each do |rbook|
            book = books.get_book(rbook[:ean13], rbook[:gln_distributor])
            book.onix = rbook[:onix_product]
          end
        else
          book = books.get_book(message[:ean13], message[:gln_distributor])
          book.onix = message[:onix_product]
        end
        books
      else
        nil
      end
    end

    # Vérification de la disponibilité du livre en argument
    # @param [Book] book
    # @return [Book]
    def get_book_availability(book, country = "FR")
      self.get_books_availability(Books.new([book]), country)
      book
    end

    # Vérification de la disponibilité des livres en argument
    # @param [Books] book
    # @return [Books, nil]
    def get_books_availability(books, country = "FR")
      books_h = books.to_hash([:ean13, :gln_distributor, :unit_price, :unit_price_excluding_tax, :currency])
      books_h.each do |book|
        book[:unit_price_excluding_tax] = calculated_unit_price_excl_tax(book[:unit_price], country)
      end
      response = @client.call(:check_availability, message_with_auth({ glnContractor: @glnContractor }.merge({ country: country }).merge({ check_availability_line: books_h })))
      message = response.body[:check_availability_response][:check_availability_response_line]
      if message
        case message
        when Array
          message.each do |rline|
            book = books.get_book(rline[:ean13], rline[:gln_distributor])
            book.available = rline[:check_availability_return_value] == "AVAILABLE" ? true : false
            book.message = rline[:return_message]
          end
        else
          book = books.get_book(message[:ean13], message[:gln_distributor])
          book.available = message[:check_availability_return_value] == "AVAILABLE" ? true : false
          book.message = message[:return_message]
        end
        books
      else
        nil
      end
    end

    # Passage d'une commande
    # @param [Order] order
    # @param [Customer] customer
    # @param [Customer] book_owner
    # @return [void]
    def send_order(order, customer, book_owner = nil)
      unless book_owner
        book_owner = customer
      end
      order_line_h = order.to_hash([:order_request_line])
      order_line_h[:order_request_line].each do |line|
        line[:unit_price_excluding_tax] = calculated_unit_price_excl_tax(line[:unit_price], customer.country)
      end

      response = @client.call(:send_order, message_with_auth(order.to_hash([:order_id]).
        merge({ glnContractor: @glnContractor, glnDelivery: @glnDelivery }).
        merge({ customer_id: customer.identifier }.merge(final_book_owner: book_owner.to_hash).merge(order_line_h))))
      message = response.body[:send_order_response][:order_line]
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
    # @param [Order] order
    # @return [Order]
    def get_order(order)
      response = @client.call(:get_order_detail, message_with_auth(order.to_hash([:order_id]).merge({ glnContractor: @glnContractor })))
      message = response.body[:get_order_detail_response][:order_line]
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
      { message: { glnReseller: @glnReseller, passwordReseller: @passwordReseller }.merge(attrs.delete_if { |k, v| not v }) }
    end

    def raise_error_message(message)
      error = message[:return_status]
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
      lnk = Link.new(message[:url], message[:format], message[:mimetype], message[:ean13])
      order_line.links << lnk
    end

    def message_to_order_line(order, message)
      order_line = order.get_line(message[:ean13], message[:gln_distributor])
      unless order_line
        order_line = OrderLine.new(Book.new(message[:ean13], message[:gln_distributor]))
      end
      order_line.identifier = message[:order_line_id]
      order_line.reference = message[:line_reference]
      link_message = message[:link]
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
