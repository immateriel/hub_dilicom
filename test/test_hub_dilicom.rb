require 'helper'

# à remplacer par votre GLN/Mot de passe
TEST_GLN = "xxx"
TEST_PASSWORD = "xxx"

class TestHubDilicom < Minitest::Test

  context "book" do

    setup do
      @client = HubDilicom::Client.new(TEST_GLN, TEST_PASSWORD, true)
    end

    should "download ONIX" do
      book = HubDilicom::Book.new("9782072802522", "3012410002007", 949, "EUR")
      @client.get_book_onix(book)
      assert_equal true, book.onix != nil
    end

    should "be available in FR" do
      book = HubDilicom::Book.new("9782072802522", "3012410002007", 949, "EUR")
      @client.get_book_availability(book, "FR")
      assert_equal true, book.available
    end

    should "undefined unit tax for BE" do
      book = HubDilicom::Book.new("9782072802522", "3012410002007", 949, "EUR")
      assert_raises HubDilicom::UndefinedCalculateUnitPrice do
        @client.get_book_availability(book, "BE")
      end
    end

    should "not be available in CA" do
      book = HubDilicom::Book.new("9782072802522", "3012410002007", 949, "CAD")
      @client.define_calculate_unit_price_excl_tax do |price, country|
          price
      end
      @client.get_book_availability(book, "CA")
      assert_equal false, book.available
    end

    should "have wrong price" do
      book = HubDilicom::Book.new("9782072802522", "3012410002007", 899, "EUR")
      @client.get_book_availability(book, "FR")
      assert_equal false, book.available
    end

  end

  context "order" do
    setup do
      @client = HubDilicom::Client.new(TEST_GLN, TEST_PASSWORD, true)
    end

    should "be ordered" do
      rnd = Random.rand(32000)
      book = HubDilicom::Book.new("9782277017202", "3012410002007", 0, "EUR")

      customer = HubDilicom::Customer.new("HUBGEMTESTFR", "Jean Dupond", "FR")

      order_line = HubDilicom::OrderLine.new(book, 1)
      order = HubDilicom::Order.new("HUBGEMTEST#{rnd}", [order_line])
      @client.send_order(order, customer)

      assert_equal true, order_line.links.length > 0
    end

  end

end
