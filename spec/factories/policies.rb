FactoryBot.define do
  factory :policy do
    sequence(:number) { |n| "POL-#{n.to_s.rjust(6, '0')}" }
    issue_date { Date.current }
    start_date { Date.current }
    end_date { Date.current + 1.year }
    insured_amount { 100000.0 }
    maximum_coverage { 100000.0 }
    status { Policy::STATUS_ACTIVE }
    original_start_date { start_date }
    original_end_date { end_date }
  end
end
