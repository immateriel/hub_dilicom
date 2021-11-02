module HubDilicom
  class Order
    attr_accessor :identifier, :lines, :lines_hash

    def initialize(identifier, lines = [])
      @identifier = identifier
      @lines = []
      @lines_hash = {}
      lines.each do |line|
        self.add_line(line)
      end
    end

    # @param [OrderLine] line
    # @return [void]
    def add_line(line)
      unless @lines.include?(line)
        @lines << line
      end
      @lines_hash[[line.book.ean13, line.book.gln_distributor]] = line
    end

    # @param [String] ean13
    # @param [String] gln_distributor
    # @return [OrderLine]
    def get_line(ean13, gln_distributor)
      @lines_hash[[ean13, gln_distributor]]
    end

    def to_hash(keys)
      olh = @lines.map { |line| line.to_hash([:quantity]) }
      { order_id: @identifier, order_line: olh, order_request_line: olh }.delete_if { |k, v| not v }.select { |k, v| keys.include?(k) }
    end

  end
end
