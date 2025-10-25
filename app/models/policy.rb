class Policy < ApplicationRecord
  STATUS_ACTIVE = "ATIVA"
  STATUS_CANCELLED = "BAIXADA"

  has_many :endorsements, -> { order(created_at: :asc) }, dependent: :restrict_with_error

  validates :number, presence: true, uniqueness: true
  validates :start_date, :end_date, :insured_amount, presence: true
  validates :insured_amount, :maximum_coverage, numericality: { greater_than_or_equal_to: 0 }
  validate :end_date_must_be_after_start_date
  validate :start_date_within_valid_range

  before_validation :set_defaults, on: :create

  private

  def set_defaults
    self.issue_date ||= Date.current
    self.maximum_coverage ||= insured_amount
    self.status ||= STATUS_ACTIVE
    self.original_start_date ||= start_date
    self.original_end_date ||= end_date
  end

  def end_date_must_be_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def start_date_within_valid_range
    return if start_date.blank? || issue_date.blank?

    issue = issue_date || Date.current
    days_difference = (start_date - issue).to_i

    if days_difference.abs > 30
      errors.add(:start_date, "must be within 30 days of issue date (past or future)")
    end
  end
end
