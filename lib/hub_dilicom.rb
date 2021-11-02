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

  class UndefinedCalculateUnitPrice < StandardError
  end
end

require 'hub_dilicom/book'
require 'hub_dilicom/books'
require 'hub_dilicom/link'
require 'hub_dilicom/order_line'
require 'hub_dilicom/order'
require 'hub_dilicom/customer'
require 'hub_dilicom/client'
