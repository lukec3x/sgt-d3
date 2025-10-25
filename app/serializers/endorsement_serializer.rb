class EndorsementSerializer < ActiveModel::Serializer
  attributes :id, :policy_id, :issue_date, :endorsement_type,
             :insured_amount, :start_date, :end_date,
             :cancelled_endorsement_id, :status
end
