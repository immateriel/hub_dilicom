module HubDilicom
  class Books
    attr_accessor :books, :books_hash

    def initialize(books)
      @books = []
      @books_hash = {}
      books.each do |book|
        self.add_book(book)
      end
    end

    # @param [Book]
    # @return [void]
    def add_book(book)
      @books << book
      @books_hash[[book.ean13, book.gln_distributor]] = book
    end

    # @param [String] ean13
    # @param [String] gln_distributor
    # @return [Book]
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
end
