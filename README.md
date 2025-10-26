# API de Apólices e Endossos

API desenvolvida em Ruby on Rails para gerenciar apólices de seguro e seus endossos.

## Como Rodar a API

1. Clone o repositório:
```bash
git clone git@github.com:lukec3x/sgt-d3.git
cd sgt-d3
```

2. Suba os containers:
```bash
docker-compose up -d
```

O Docker irá automaticamente configurar os bancos de dados de desenvolvimento e teste.

3. A API estará disponível em: **http://localhost:3000**

### Parando a aplicação

```bash
docker-compose down
```

## Como Rodar os Testes

### Todos os testes:
```bash
docker-compose exec web rspec
```

### Testes específicos:
```bash
# Testes do controller Endorsement
docker-compose exec web rspec spec/controllers/endorsements_controller_spec.rb

# Testes do controller Policy
docker-compose exec web rspec spec/controllers/policies_controller_spec.rb
```

## Collection do Postman

Uma collection completa está incluída no arquivo `postman_collection.json`.

### Como usar:

1. Abra o Postman
2. Clique em **Import**
3. Selecione o arquivo `postman_collection.json`
4. A collection "SGT - Desafio 3" será importada com todos os endpoints
5. **Crie um Environment** com a variável `base_url` apontando para `http://localhost:3000`
6. Selecione o environment criado antes de executar as requisições

### Automação:

A collection possui automação entre requisições:
- Ao criar uma policy com `POST /policies`, o `policy_id` é automaticamente salvo no environment
- Ao criar um endosso com `POST /policies/:policy_id/endorsements`, o `endorsement_id` é automaticamente salvo no environment
- Esses IDs são usados automaticamente pelas demais requisições

### O que está incluído:

**Policies (Apólices)**
- `GET /policies` - Listar todas as apólices
- `GET /policies/:id` - Consultar apólice específica
- `POST /policies` - Criar nova apólice

**Endorsements (Endossos)**
- `GET /policies/:policy_id/endorsements` - Listar endossos de uma apólice
- `GET /endorsements/:id` - Consultar endosso específico
- `POST /policies/:policy_id/endorsements` - Criar novo endosso
- `POST /policies/:policy_id/endorsements/cancel` - Cancelar último endosso válido
