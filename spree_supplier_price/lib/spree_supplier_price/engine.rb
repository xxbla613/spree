# frozen_string_literal: true
module SpreeSupplierPrice
  class Engine < ::Rails::Engine
    engine_name 'spree_supplier_price'

    initializer 'spree_supplier_price.dependencies' do
      Spree.dependencies do |dependencies|
        dependencies.carts_complete_workflow = 'SpreeSupplierPrice::Carts::Complete'
        dependencies.order_complete_workflow = 'SpreeSupplierPrice::Orders::Complete'
        dependencies.commissions_commission_order_service = 'SpreeSupplierPrice::Commissions::CommissionOrder'
      end
    end

    config.to_prepare do
      Spree::Seller.include SpreeSupplierPrice::SellerDecorator unless Spree::Seller < SpreeSupplierPrice::SellerDecorator
      Spree::LineItem.include SpreeSupplierPrice::LineItemDecorator unless Spree::LineItem < SpreeSupplierPrice::LineItemDecorator
    end
  end
end
