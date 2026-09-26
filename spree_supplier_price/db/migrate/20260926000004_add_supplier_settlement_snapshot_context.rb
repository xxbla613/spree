# frozen_string_literal: true

class AddSupplierSettlementSnapshotContext < ActiveRecord::Migration[8.1]
  def change
    # NULL is a legacy/unprepared line, not today's seller configuration.
    add_column :spree_line_items, :supplier_settlement_mode, :string
    add_column :spree_line_items, :supplier_price_currency, :string
    add_reference :spree_line_items, :supplier_price_record,
                  foreign_key: { to_table: :spree_supplier_prices }
    add_check_constraint :spree_line_items,
                         "supplier_settlement_mode IS NULL OR supplier_settlement_mode IN ('commission', 'supplier_price')",
                         name: 'chk_supplier_settlement_mode_snapshot'
    add_check_constraint :spree_line_items,
                         "supplier_settlement_mode IS NULL OR (supplier_settlement_mode = 'commission' AND supplier_price IS NULL) OR (supplier_settlement_mode = 'supplier_price' AND supplier_price IS NOT NULL AND supplier_price_currency IS NOT NULL AND supplier_price_record_id IS NOT NULL)",
                         name: 'chk_supplier_settlement_snapshot_complete'
  end
end
