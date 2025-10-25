class PoliciesController < ApplicationController
  before_action :set_policy, only: %i[ show ]

  # GET /policies
  def index
    @policies = Policy.includes(:endorsements).order(created_at: :desc)

    render json: @policies
  end

  # GET /policies/1
  def show
    render json: @policy
  end

  # POST /policies
  def create
    @policy = Policy.new(policy_params)

    if @policy.save
      render json: @policy, status: :created, location: @policy
    else
      render json: @policy.errors, status: :unprocessable_content
    end
  end

  private

  def set_policy
    @policy = Policy.find(params.expect(:id))
  end

  def policy_params
    params.expect(policy: [ :number, :start_date, :end_date, :insured_amount ])
  end
end
