# frozen_string_literal: true

require 'bigdecimal'
require 'bigdecimal/util'

module Spree
  module SupplierPrices
    class Calculate
      class MissingSnapshot < StandardError; end
      class InvalidSnapshot < StandardError; end

      def self.call(line_item:)
        snapshot = line_item.supplier_price

        raise MissingSnapshot,
              'Supplier-price settlement requires a placement snapshot' if snapshot.nil?

        amount = snapshot.to_d

        unless amount.finite? && amount.positive?
          raise InvalidSnapshot,
                'Supplier-price snapshot must be positive'
        end

        # The snapshot survives subsequent seller mode changes.
        # This is seller merchandise cost, not platform commission.
        amount * line_item.quantity.to_d
      end
    end
  end
end