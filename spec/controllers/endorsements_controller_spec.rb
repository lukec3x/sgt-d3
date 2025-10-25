require 'rails_helper'

RSpec.describe EndorsementsController, type: :controller do
  let(:policy) { create(:policy) }

  describe "GET #index" do
    context "quando a apólice existe" do
      let!(:endorsement1) { create(:endorsement, :increase_is, policy: policy) }
      let!(:endorsement2) { create(:endorsement, :change_validity, policy: policy) }

      before { get :index, params: { policy_id: policy.id } }

      it "retorna status 200" do
        expect(response).to have_http_status(:ok)
      end

      it "retorna todos os endossos da apólice" do
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(2)
      end
    end

    context "quando a apólice não existe" do
      before { get :index, params: { policy_id: 99999 } }

      it "retorna status 404" do
        expect(response).to have_http_status(:not_found)
      end

      it "retorna mensagem de erro" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end
  end

  describe "GET #show" do
    context "quando o endosso existe" do
      let(:endorsement) { create(:endorsement, :increase_is, policy: policy) }

      before { get :show, params: { id: endorsement.id } }

      it "retorna status 200" do
        expect(response).to have_http_status(:ok)
      end

      it "retorna o endosso correto" do
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(endorsement.id)
        expect(json_response['endorsement_type']).to eq(Endorsement::TYPE_INCREASE_IS)
      end
    end

    context "quando o endosso não existe" do
      before { get :show, params: { id: 99999 } }

      it "retorna status 404" do
        expect(response).to have_http_status(:not_found)
      end

      it "retorna mensagem de erro" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end
  end

  describe "POST #create" do
    context "com parâmetros válidos para aumento de IS" do
      let(:valid_params) do
        {
          policy_id: policy.id,
          endorsement: {
            insured_amount: 150000.0
          }
        }
      end

      it "cria um novo endosso" do
        expect {
          post :create, params: valid_params
        }.to change(Endorsement, :count).by(1)
      end

      it "retorna status 201 (created)" do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "retorna o endosso criado" do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['insured_amount']).to eq('150000.0')
        expect(json_response['endorsement_type']).to eq(Endorsement::TYPE_INCREASE_IS)
      end

      it "atualiza a cobertura máxima da apólice" do
        post :create, params: valid_params
        expect(policy.reload.maximum_coverage).to eq(150000.0)
      end
    end

    context "com parâmetros válidos para redução de IS" do
      let(:valid_params) do
        {
          policy_id: policy.id,
          endorsement: {
            insured_amount: 50000.0
          }
        }
      end

      it "cria um endosso de redução" do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['endorsement_type']).to eq(Endorsement::TYPE_DECREASE_IS)
      end

      it "atualiza a cobertura máxima da apólice" do
        post :create, params: valid_params
        expect(policy.reload.maximum_coverage).to eq(50000.0)
      end
    end

    context "com parâmetros válidos para alteração de vigência" do
      let(:valid_params) do
        {
          policy_id: policy.id,
          endorsement: {
            start_date: Date.current + 1.month,
            end_date: Date.current + 1.year + 1.month
          }
        }
      end

      it "cria um endosso de alteração de vigência" do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['endorsement_type']).to eq(Endorsement::TYPE_CHANGE_VALIDITY)
      end

      it "atualiza as datas da apólice" do
        post :create, params: valid_params
        policy.reload
        expect(policy.start_date).to eq(Date.current + 1.month)
        expect(policy.end_date).to eq(Date.current + 1.year + 1.month)
      end
    end

    context "com parâmetros válidos para aumento de IS e alteração de vigência" do
      let(:valid_params) do
        {
          policy_id: policy.id,
          endorsement: {
            insured_amount: 150000.0,
            start_date: Date.current + 1.month,
            end_date: Date.current + 1.year + 1.month
          }
        }
      end

      it "cria um endosso combinado" do
        post :create, params: valid_params
        json_response = JSON.parse(response.body)
        expect(json_response['endorsement_type']).to eq(Endorsement::TYPE_INCREASE_IS_AND_VALIDITY)
      end

      it "atualiza tanto a cobertura quanto as datas" do
        post :create, params: valid_params
        policy.reload
        expect(policy.maximum_coverage).to eq(150000.0)
        expect(policy.start_date).to eq(Date.current + 1.month)
      end
    end

    context "com parâmetros inválidos" do
      let(:invalid_params) do
        {
          policy_id: policy.id,
          endorsement: {
            insured_amount: -1000.0
          }
        }
      end

      it "não cria um novo endosso" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Endorsement, :count)
      end

      it "retorna status 422 (unprocessable_content)" do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "retorna os erros de validação" do
        post :create, params: invalid_params
        json_response = JSON.parse(response.body)
        expect(json_response['insured_amount']).to include('cannot be negative')
      end
    end

    context "quando a apólice não existe" do
      before do
        post :create, params: {
          policy_id: 99999,
          endorsement: { insured_amount: 150000.0 }
        }
      end

      it "retorna status 404" do
        expect(response).to have_http_status(:not_found)
      end

      it "retorna mensagem de erro" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end

    context "quando nenhuma mudança é especificada" do
      let(:no_change_params) do
        {
          policy_id: policy.id,
          endorsement: {
            insured_amount: policy.insured_amount,
            start_date: policy.start_date,
            end_date: policy.end_date
          }
        }
      end

      it "não cria um endosso" do
        expect {
          post :create, params: no_change_params
        }.not_to change(Endorsement, :count)
      end

      it "retorna status 422" do
        post :create, params: no_change_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST #cancel" do
    context "quando existe um endosso para cancelar" do
      let!(:endorsement) { create(:endorsement, :increase_is, policy: policy) }

      it "cria um endosso de cancelamento" do
        expect {
          post :cancel, params: { policy_id: policy.id }
        }.to change(Endorsement, :count).by(1)
      end

      it "retorna status 201 (created)" do
        post :cancel, params: { policy_id: policy.id }
        expect(response).to have_http_status(:created)
      end

      it "cria um endosso do tipo cancelamento" do
        post :cancel, params: { policy_id: policy.id }
        json_response = JSON.parse(response.body)
        expect(json_response['endorsement_type']).to eq(Endorsement::TYPE_CANCELLATION)
      end

      it "marca o último endosso como cancelado" do
        post :cancel, params: { policy_id: policy.id }
        expect(endorsement.reload.status).to eq(Endorsement::STATUS_CANCELLED)
      end

      it "reverte as mudanças da apólice" do
        original_coverage = policy.insured_amount
        policy.reload
        expect(policy.maximum_coverage).to eq(150000.0)

        post :cancel, params: { policy_id: policy.id }
        policy.reload
        expect(policy.maximum_coverage).to eq(original_coverage)
      end

      it "define o cancelled_endorsement_id corretamente" do
        post :cancel, params: { policy_id: policy.id }
        json_response = JSON.parse(response.body)
        cancellation = Endorsement.find(json_response['id'])
        expect(cancellation.cancelled_endorsement_id).to eq(endorsement.id)
      end
    end

    context "quando existem múltiplos endossos" do
      let!(:endorsement1) { create(:endorsement, :increase_is, policy: policy) }
      let!(:endorsement2) { create(:endorsement, :change_validity, policy: policy) }

      it "cancela apenas o último endosso" do
        last_endorsement = policy.endorsements.active.where.not(endorsement_type: Endorsement::TYPE_CANCELLATION).order(created_at: :desc).first

        post :cancel, params: { policy_id: policy.id }

        expect(last_endorsement.reload.status).to eq(Endorsement::STATUS_CANCELLED)
      end

      it "recalcula a apólice com base nos endossos restantes" do
        expect(policy.endorsements.active.count).to eq(2)
        initial_coverage = policy.reload.maximum_coverage

        post :cancel, params: { policy_id: policy.id }
        policy.reload

        active_non_cancel = policy.endorsements.active.where.not(endorsement_type: Endorsement::TYPE_CANCELLATION)
        expect(active_non_cancel.count).to eq(1)

        remaining_endorsement = active_non_cancel.first

        if remaining_endorsement.insured_amount.present?
          expect(policy.maximum_coverage.to_f).to eq(remaining_endorsement.insured_amount.to_f)
        else
          expect(policy.maximum_coverage.to_f).to eq(policy.insured_amount.to_f)
        end
      end
    end

    context "quando não existe endosso para cancelar" do
      it "não cria um endosso de cancelamento" do
        expect {
          post :cancel, params: { policy_id: policy.id }
        }.not_to change(Endorsement, :count)
      end

      it "retorna status 422" do
        post :cancel, params: { policy_id: policy.id }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "retorna uma mensagem de erro" do
        post :cancel, params: { policy_id: policy.id }
        json_response = JSON.parse(response.body)
        expect(json_response['base']).to include('No endorsement to cancel')
      end
    end

    context "quando a apólice não existe" do
      before { post :cancel, params: { policy_id: 99999 } }

      it "retorna status 404" do
        expect(response).to have_http_status(:not_found)
      end

      it "retorna mensagem de erro" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end

    context "quando o último endosso já é um cancelamento" do
      let!(:endorsement) { create(:endorsement, :increase_is, policy: policy, created_at: 2.days.ago) }
      let!(:cancellation) do
        Endorsement.create!(
          policy: policy,
          endorsement_type: Endorsement::TYPE_CANCELLATION,
          cancelled_endorsement_id: endorsement.id
        )
      end

      before do
        endorsement.update_column(:status, Endorsement::STATUS_CANCELLED)
      end

      it "não cria outro cancelamento" do
        expect {
          post :cancel, params: { policy_id: policy.id }
        }.not_to change(Endorsement, :count)
      end

      it "retorna status 422" do
        post :cancel, params: { policy_id: policy.id }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
