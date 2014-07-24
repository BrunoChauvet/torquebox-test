class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.time :placed_on
      t.time :packed_on
      t.time :delivered_on
      t.text :description
      t.text :status

      t.timestamps
    end
  end
end
