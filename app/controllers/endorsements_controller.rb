class EndorsementsController < ApplicationController
  before_action :set_policy, only: [:index, :create, :cancel]
  before_action :set_endorsement, only: [:show]

  # GET /policies/:policy_id/endorsements
  def index
    @endorsements = @policy.endorsements.order(created_at: :desc)
    render json: @endorsements
  end

  # GET /endorsements/:id
  def show
    render json: @endorsement
  end

  # POST /policies/:policy_id/endorsements
  def create
    @endorsement = @policy.endorsements.new(endorsement_params)

    if @endorsement.save
      render json: @endorsement, status: :created, location: @endorsement
    else
      render json: @endorsement.errors, status: :unprocessable_content
    end
  end

  # POST /policies/:policy_id/endorsements/cancel
  def cancel
    @endorsement = @policy.endorsements.new(endorsement_type: Endorsement::TYPE_CANCELLATION)

    if @endorsement.save
      render json: @endorsement, status: :created, location: @endorsement
    else
      render json: @endorsement.errors, status: :unprocessable_content
    end
  end

  private
    def set_policy
      @policy = Policy.find(params[:policy_id])
    end

    def set_endorsement
      @endorsement = Endorsement.find(params[:id])
    end

    def endorsement_params
      params.expect(endorsement: [:insured_amount, :start_date, :end_date])
    end
end
