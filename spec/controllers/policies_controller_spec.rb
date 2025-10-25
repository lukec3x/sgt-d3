require 'rails_helper'

RSpec.describe PoliciesController, type: :controller do
  describe "GET #index" do
    context "quando não há apólices" do
      before { get :index }

      it "retorna status 200" do
        expect(response).to have_http_status(:ok)
      end

      it "retorna um array vazio" do
        json_response = JSON.parse(response.body)
        expect(json_response).to eq([])
      end
    end

    context "quando há apólices cadastradas" do
      let!(:policy1) { create(:policy, number: "POL-001") }
      let!(:policy2) { create(:policy, number: "POL-002") }

      before { get :index }

      it "retorna status 200" do
        expect(response).to have_http_status(:ok)
      end

      it "retorna todas as apólices" do
        json_response = JSON.parse(response.body)
        expect(json_response.length).to eq(2)
        expect(json_response.map { |p| p['number'] }).to contain_exactly("POL-001", "POL-002")
      end
    end
  end

  describe "GET #show" do
    context "quando a apólice existe" do
      let(:policy) { create(:policy, number: "POL-123") }

      before { get :show, params: { id: policy.id } }

      it "retorna status 200" do
        expect(response).to have_http_status(:ok)
      end

      it "retorna a apólice correta" do
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(policy.id)
        expect(json_response['number']).to eq("POL-123")
      end
    end

    context "quando a apólice existe e tem endossos" do
      let(:policy) { create(:policy) }
      let!(:endorsement1) { create(:endorsement, :increase_is, policy: policy) }
      let!(:endorsement2) { create(:endorsement, :change_validity, policy: policy) }

      before { get :show, params: { id: policy.id } }

      it "retorna os endossos associados" do
        json_response = JSON.parse(response.body)
        expect(json_response['endorsements'].length).to eq(2)
        endorsement_types = json_response['endorsements'].map { |e| e['endorsement_type'] }
        expect(endorsement_types).to contain_exactly(
          Endorsement::TYPE_INCREASE_IS,
          Endorsement::TYPE_CHANGE_VALIDITY
        )
      end
    end

    context "quando a apólice não existe" do
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
    context "com parâmetros válidos" do
      let(:valid_params) do
        {
          policy: {
            number: "POL-2024-001",
            start_date: Date.current,
            end_date: Date.current + 1.year,
            insured_amount: 100000.0
          }
        }
      end

      it "cria uma nova apólice" do
        expect {
          post :create, params: valid_params
        }.to change(Policy, :count).by(1)
      end

      context "resposta da criação" do
        before { post :create, params: valid_params }

        it "retorna status 201 (created)" do
          expect(response).to have_http_status(:created)
        end

        it "retorna a apólice criada" do
          json_response = JSON.parse(response.body)
          expect(json_response['number']).to eq("POL-2024-001")
          expect(json_response['insured_amount']).to eq("100000.0")
        end

        it "define maximum_coverage igual ao insured_amount" do
          json_response = JSON.parse(response.body)
          expect(json_response['maximum_coverage']).to eq("100000.0")
        end

        it "define issue_date como a data atual" do
          json_response = JSON.parse(response.body)
          expect(json_response['issue_date']).to eq(Date.current.to_s)
        end

        it "define status como ATIVA" do
          json_response = JSON.parse(response.body)
          expect(json_response['status']).to eq(Policy::STATUS_ACTIVE)
        end
      end
    end

    context "com start_date no passado (dentro de 30 dias)" do
      let(:valid_params) do
        {
          policy: {
            number: "POL-PAST",
            start_date: Date.current - 15.days,
            end_date: Date.current + 1.year,
            insured_amount: 100000.0
          }
        }
      end

      it "cria a apólice com sucesso" do
        expect {
          post :create, params: valid_params
        }.to change(Policy, :count).by(1)
      end

      context "resposta" do
        before { post :create, params: valid_params }

        it "retorna status 201" do
          expect(response).to have_http_status(:created)
        end
      end
    end

    context "com start_date no futuro (dentro de 30 dias)" do
      let(:valid_params) do
        {
          policy: {
            number: "POL-FUTURE",
            start_date: Date.current + 15.days,
            end_date: Date.current + 1.year + 15.days,
            insured_amount: 100000.0
          }
        }
      end

      it "cria a apólice com sucesso" do
        expect {
          post :create, params: valid_params
        }.to change(Policy, :count).by(1)
      end

      context "resposta" do
        before { post :create, params: valid_params }

        it "retorna status 201" do
          expect(response).to have_http_status(:created)
        end
      end
    end

    context "com parâmetros inválidos" do
      context "quando number está ausente" do
        let(:invalid_params) do
          {
            policy: {
              start_date: Date.current,
              end_date: Date.current + 1.year,
              insured_amount: 100000.0
            }
          }
        end

        it "não cria uma nova apólice" do
          expect {
            post :create, params: invalid_params
          }.not_to change(Policy, :count)
        end

        context "resposta de erro" do
          before { post :create, params: invalid_params }

          it "retorna status 422 (unprocessable_content)" do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it "retorna mensagem de erro" do
            json_response = JSON.parse(response.body)
            expect(json_response['number']).to include("can't be blank")
          end
        end
      end

      context "quando number é duplicado" do
        let!(:existing_policy) { create(:policy, number: "POL-DUP") }
        let(:duplicate_params) do
          {
            policy: {
              number: "POL-DUP",
              start_date: Date.current,
              end_date: Date.current + 1.year,
              insured_amount: 100000.0
            }
          }
        end

        it "não cria uma nova apólice" do
          expect {
            post :create, params: duplicate_params
          }.not_to change(Policy, :count)
        end

        context "resposta de erro" do
          before { post :create, params: duplicate_params }

          it "retorna status 422" do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it "retorna mensagem de erro de unicidade" do
            json_response = JSON.parse(response.body)
            expect(json_response['number']).to include("has already been taken")
          end
        end
      end

      context "quando insured_amount é negativo" do
        let(:invalid_params) do
          {
            policy: {
              number: "POL-NEG",
              start_date: Date.current,
              end_date: Date.current + 1.year,
              insured_amount: -1000.0
            }
          }
        end

        it "não cria uma nova apólice" do
          expect {
            post :create, params: invalid_params
          }.not_to change(Policy, :count)
        end

        context "resposta de erro" do
          before { post :create, params: invalid_params }

          it "retorna status 422" do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it "retorna mensagem de erro de validação numérica" do
            json_response = JSON.parse(response.body)
            expect(json_response['insured_amount']).to include("must be greater than or equal to 0")
          end
        end
      end

      context "quando end_date é anterior a start_date" do
        let(:invalid_params) do
          {
            policy: {
              number: "POL-DATES",
              start_date: Date.current + 1.year,
              end_date: Date.current,
              insured_amount: 100000.0
            }
          }
        end

        it "não cria uma nova apólice" do
          expect {
            post :create, params: invalid_params
          }.not_to change(Policy, :count)
        end

        context "resposta de erro" do
          before { post :create, params: invalid_params }

          it "retorna status 422" do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it "retorna mensagem de erro de validação de datas" do
            json_response = JSON.parse(response.body)
            expect(json_response['end_date']).to include("must be after start date")
          end
        end
      end

      context "quando start_date está fora do range de 30 dias" do
        let(:invalid_params) do
          {
            policy: {
              number: "POL-OUT-RANGE",
              start_date: Date.current + 45.days,
              end_date: Date.current + 1.year + 45.days,
              insured_amount: 100000.0
            }
          }
        end

        it "não cria uma nova apólice" do
          expect {
            post :create, params: invalid_params
          }.not_to change(Policy, :count)
        end

        context "resposta de erro" do
          before { post :create, params: invalid_params }

          it "retorna status 422" do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it "retorna mensagem de erro sobre o range de datas" do
            json_response = JSON.parse(response.body)
            expect(json_response['start_date']).to include("must be within 30 days of issue date (past or future)")
          end
        end
      end

      context "quando campos obrigatórios estão ausentes" do
        let(:invalid_params) do
          {
            policy: {
              number: "POL-MISSING"
            }
          }
        end

        it "não cria uma nova apólice" do
          expect {
            post :create, params: invalid_params
          }.not_to change(Policy, :count)
        end

        context "resposta de erro" do
          before { post :create, params: invalid_params }

          it "retorna status 422" do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it "retorna mensagens de erro para todos os campos ausentes" do
            json_response = JSON.parse(response.body)
            expect(json_response).to have_key('start_date')
            expect(json_response).to have_key('end_date')
            expect(json_response).to have_key('insured_amount')
          end
        end
      end
    end
  end
end
