# frozen_string_literal: true
class AddSettlementModeToSpreeSellers < ActiveRecord::Migration[8.1]
  def change
    add_column :spree_sellers, :settlement_mode, :integer, null: false, default: 0
    add_index :spree_sellers, :settlement_mode
    add_check_constraint :spree_sellers, 'settlement_mode IN (0, 1)',
                         name: 'chk_spree_sellers_settlement_mode'
  end
end
