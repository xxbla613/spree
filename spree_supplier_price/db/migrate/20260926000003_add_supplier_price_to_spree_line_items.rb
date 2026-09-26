# frozen_string_literal: true
class AddSupplierPriceToSpreeLineItems < ActiveRecord::Migration[8.1]
  def change
    # NULL means no snapshot, never a zero supplier price.
    add_column :spree_line_items, :supplier_price, :decimal, precision: 20, scale: 4
    add_check_constraint :spree_line_items, 'supplier_price IS NULL OR supplier_price > 0',
                         name: 'chk_spree_line_items_supplier_price'
  end
end
