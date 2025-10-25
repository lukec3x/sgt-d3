class PolicySerializer < ActiveModel::Serializer
  attributes :id, :number, :issue_date, :start_date, :end_date,
             :insured_amount, :maximum_coverage, :status

  has_many :endorsements
end
