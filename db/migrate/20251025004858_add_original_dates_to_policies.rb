class AddOriginalDatesToPolicies < ActiveRecord::Migration[8.0]
  def change
    add_column :policies, :original_start_date, :date
    add_column :policies, :original_end_date, :date
  end
end
