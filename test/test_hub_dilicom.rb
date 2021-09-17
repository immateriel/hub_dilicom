# coding: utf-8
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
      book = HubDilicom::Book.new("9782072495229", "3012410002007", 949, "EUR")
      @client.get_book_onix(book)
      assert_equal true, book.onix != nil
    end

    should "be available in FR" do
      book = HubDilicom::Book.new("9782072495229", "3012410002007", 949, "EUR")
      @client.get_book_availability(book, "FR")
      assert_equal true, book.available
    end

    should "be available in BE" do
      book = HubDilicom::Book.new("9782072495229", "3012410002007", 949, "EUR")
      @client.get_book_availability(book, "BE")
      assert_equal true, book.available
    end

    should "not be available in CA" do
      book = HubDilicom::Book.new("9782072495229", "3012410002007", 949, "CAD")
      @client.get_book_availability(book, "CA")
      assert_equal false, book.available
    end

    should "have wrong price" do
      book = HubDilicom::Book.new("9782072495229", "3012410002007", 899, "EUR")
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
      book = HubDilicom::Book.new("9782361832179", "3012410002007", 0, "EUR")

      customer = HubDilicom::Customer.new("HUBGEMTESTFR", "Jean Dupond", "FR")

      order_line = HubDilicom::OrderLine.new(book, 1)
      order = HubDilicom::Order.new("HUBGEMTEST#{rnd}", [order_line])
      @client.send_order(order, customer)

      #      puts order_line.links.first.url
      assert_equal true, order_line.links.length > 0
    end

  end

end