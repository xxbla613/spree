# frozen_string_literal: true
class CreateSpreeSupplierPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :spree_supplier_prices do |t|
      t.references :seller, null: false, foreign_key: { to_table: :spree_sellers }
      t.references :variant, null: false, foreign_key: { to_table: :spree_variants }
      t.decimal :amount, precision: 20, scale: 4, null: false
      t.string :currency, null: false
      t.integer :state, null: false, default: 0
      t.references :submitted_by, foreign_key: { to_table: Spree.admin_user_class.to_s.constantize.table_name }
      t.references :approved_by, foreign_key: { to_table: Spree.admin_user_class.to_s.constantize.table_name }
      t.datetime :approved_at
      t.timestamps
      t.check_constraint 'amount > 0', name: 'chk_spree_supplier_prices_positive_amount'
      t.check_constraint 'state IN (0, 1)', name: 'chk_spree_supplier_prices_state'
      t.check_constraint 'state <> 1 OR approved_at IS NOT NULL',
                         name: 'chk_spree_supplier_prices_approval_time'
    end
    add_index :spree_supplier_prices, [:seller_id, :variant_id, :currency, :state, :approved_at, :id],
              name: 'idx_spree_supplier_prices_lookup'
  end
end
