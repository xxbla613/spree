# frozen_string_literal: true
module SpreeSupplierPrice
  module SellerDecorator
    extend ActiveSupport::Concern
    included do
      enum :settlement_mode, { commission: 0, supplier_price: 1 }, default: :commission
      has_many :supplier_prices, class_name: 'Spree::SupplierPrice', foreign_key: :seller_id,
                                 inverse_of: :seller, dependent: :restrict_with_error
    end
    def supplier_price_settlement?
      supplier_price?
    end
  end
end
