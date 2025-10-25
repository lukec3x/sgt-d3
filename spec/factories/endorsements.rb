FactoryBot.define do
  factory :endorsement do
    association :policy
    issue_date { Date.current }
    status { Endorsement::STATUS_ACTIVE }

    trait :increase_is do
      insured_amount { 150000.0 }
      endorsement_type { Endorsement::TYPE_INCREASE_IS }
    end

    trait :decrease_is do
      insured_amount { 50000.0 }
      endorsement_type { Endorsement::TYPE_DECREASE_IS }
    end

    trait :change_validity do
      start_date { Date.current + 1.month }
      end_date { Date.current + 1.year + 1.month }
      endorsement_type { Endorsement::TYPE_CHANGE_VALIDITY }
    end

    trait :cancellation do
      endorsement_type { Endorsement::TYPE_CANCELLATION }
    end
  end
end
