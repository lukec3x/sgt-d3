class CreateEndorsements < ActiveRecord::Migration[8.0]
  def change
    create_table :endorsements do |t|
      t.references :policy, null: false, foreign_key: true
      t.date :issue_date
      t.string :endorsement_type
      t.decimal :insured_amount, precision: 15, scale: 2
      t.date :start_date
      t.date :end_date
      t.integer :cancelled_endorsement_id
      t.string :status

      t.timestamps
    end

    add_index :endorsements, :cancelled_endorsement_id
    add_index :endorsements, :status
    add_index :endorsements, :endorsement_type
  end
end
