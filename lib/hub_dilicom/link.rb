module HubDilicom
  class Link
    attr_accessor :url, :format, :mimetype, :ean13

    def initialize(url, format, mimetype, ean13)
      @url = url
      @format = format
      @mimetype = mimetype
      @ean13 = ean13
    end
  end
end
