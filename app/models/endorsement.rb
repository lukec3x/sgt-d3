class Endorsement < ApplicationRecord
  TYPE_INCREASE_IS = "aumento_is"
  TYPE_DECREASE_IS = "reducao_is"
  TYPE_CHANGE_VALIDITY = "alteracao_vigencia"
  TYPE_INCREASE_IS_AND_VALIDITY = "aumento_is_alteracao_vigencia"
  TYPE_DECREASE_IS_AND_VALIDITY = "reducao_is_alteracao_vigencia"
  TYPE_CANCELLATION = "cancelamento"

  STATUS_ACTIVE = "ativo"
  STATUS_CANCELLED = "cancelado"

  belongs_to :policy
  belongs_to :cancelled_endorsement, class_name: "Endorsement", optional: true
  has_many :cancelling_endorsements, class_name: "Endorsement", foreign_key: :cancelled_endorsement_id

  validates :endorsement_type, presence: true
  validates :status, presence: true
  validate :validate_endorsement_fields
  validate :validate_maximum_coverage_not_negative
  validate :validate_dates_consistency

  before_validation :set_defaults, on: :create
  before_validation :determine_endorsement_type, on: :create
  before_validation :set_cancelled_endorsement, on: :create
  after_create :update_policy_data

  scope :active, -> { where(status: STATUS_ACTIVE) }
  scope :cancelled, -> { where(status: STATUS_CANCELLED) }

  private

  def set_defaults
    self.issue_date ||= Date.current
    self.status ||= STATUS_ACTIVE
  end

  def determine_endorsement_type
    return if endorsement_type == TYPE_CANCELLATION

    self.insured_amount = nil if insured_amount.present? && insured_amount == policy.maximum_coverage
    self.start_date = nil if start_date.present? && start_date == policy.start_date
    self.end_date = nil if end_date.present? && end_date == policy.end_date

    has_is_change = insured_amount.present? && insured_amount != policy.maximum_coverage
    has_validity_change = (start_date.present? && start_date != policy.start_date) ||
                          (end_date.present? && end_date != policy.end_date)

    if has_is_change && has_validity_change
      if insured_amount > policy.maximum_coverage
        self.endorsement_type = TYPE_INCREASE_IS_AND_VALIDITY
      else
        self.endorsement_type = TYPE_DECREASE_IS_AND_VALIDITY
      end
    elsif has_is_change
      if insured_amount > policy.maximum_coverage
        self.endorsement_type = TYPE_INCREASE_IS
      else
        self.endorsement_type = TYPE_DECREASE_IS
      end
    elsif has_validity_change
      self.endorsement_type = TYPE_CHANGE_VALIDITY
    end
  end

  def set_cancelled_endorsement
    return unless endorsement_type == TYPE_CANCELLATION

    last_valid = policy.endorsements.active
                       .where.not(endorsement_type: TYPE_CANCELLATION)
                       .order(created_at: :desc)
                       .first
    
    self.cancelled_endorsement_id = last_valid&.id
  end

  def validate_endorsement_fields
    case endorsement_type
    when TYPE_CANCELLATION
      validate_cancellation_endorsement
    when TYPE_INCREASE_IS, TYPE_DECREASE_IS
      validate_is_change_endorsement
    when TYPE_CHANGE_VALIDITY
      validate_validity_change_endorsement
    when TYPE_INCREASE_IS_AND_VALIDITY, TYPE_DECREASE_IS_AND_VALIDITY
      validate_is_and_validity_change_endorsement
    end
  end

  def validate_cancellation_endorsement
    if cancelled_endorsement_id.nil?
      errors.add(:base, "No endorsement to cancel")
    end
  end

  def validate_is_change_endorsement
    if insured_amount.blank?
      errors.add(:insured_amount, "must be present for this endorsement type")
    end
  end

  def validate_validity_change_endorsement
    if start_date.blank? && end_date.blank?
      errors.add(:base, "must change at least one validity date")
    end
  end

  def validate_is_and_validity_change_endorsement
    validate_is_change_endorsement
    validate_validity_change_endorsement
  end

  def validate_maximum_coverage_not_negative
    return unless insured_amount.present?

    if insured_amount < 0
      errors.add(:insured_amount, "cannot be negative")
    end
  end

  def validate_dates_consistency
    return if start_date.blank? || end_date.blank?

    effective_start = start_date || policy.start_date
    effective_end = end_date || policy.end_date

    if effective_end < effective_start
      errors.add(:end_date, "must be after start date")
    end
  end

  def update_policy_data
    if endorsement_type == TYPE_CANCELLATION
      cancel_last_endorsement
    else
      apply_endorsement_to_policy
    end
  end

  def cancel_last_endorsement
    return unless cancelled_endorsement

    cancelled_endorsement.update_column(:status, STATUS_CANCELLED)
    recalculate_policy_from_scratch
  end

  def apply_endorsement_to_policy
    policy.update_columns(
      maximum_coverage: insured_amount || policy.maximum_coverage,
      start_date: start_date || policy.start_date,
      end_date: end_date || policy.end_date
    )
    update_policy_status
  end

  def recalculate_policy_from_scratch
    policy.reload
    
    policy.update_columns(
      maximum_coverage: policy.insured_amount,
      start_date: policy.original_start_date,
      end_date: policy.original_end_date
    )
    
    active_endorsements = policy.endorsements.active
                                .where.not(endorsement_type: TYPE_CANCELLATION)
                                .order(created_at: :asc)
    
    active_endorsements.each do |endorsement|
      policy.update_columns(
        maximum_coverage: endorsement.insured_amount || policy.maximum_coverage,
        start_date: endorsement.start_date || policy.start_date,
        end_date: endorsement.end_date || policy.end_date
      )
    end
    
    update_policy_status
  end

  def update_policy_status
    policy.reload
    
    current_date = Date.current
    within_validity = policy.start_date <= current_date && policy.end_date >= current_date
    
    days_difference = (policy.start_date - policy.issue_date).to_i.abs
    start_date_valid = days_difference <= 30
    
    new_status = (within_validity && start_date_valid) ? Policy::STATUS_ACTIVE : Policy::STATUS_CANCELLED
    
    policy.update_columns(status: new_status)
  end
end
