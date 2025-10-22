class CreatePolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :policies do |t|
      t.string :number
      t.date :issue_date
      t.date :start_date
      t.date :end_date
      t.decimal :insured_amount, precision: 15, scale: 2
      t.decimal :maximum_coverage, precision: 15, scale: 2
      t.string :status

      t.timestamps
    end
    add_index :policies, :number, unique: true
  end
end
