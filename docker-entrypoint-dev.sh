#!/bin/bash
set -e

echo "=== Docker Development Entrypoint ==="
echo "DATABASE_HOST: ${DATABASE_HOST}"
echo "RAILS_ENV: ${RAILS_ENV}"

# Limpar cache do Bootsnap
echo "Limpando cache do Bootsnap..."
rm -rf tmp/cache
find tmp/pids -type f -name "*.pid" -delete 2>/dev/null || true

# Preparar banco de dados de desenvolvimento
echo "Criando banco de dados de desenvolvimento..."
bundle exec rails db:create || true

echo "Rodando migrations no ambiente de desenvolvimento..."
bundle exec rails db:migrate

# Preparar banco de dados de teste
echo "Criando banco de dados de teste..."
RAILS_ENV=test bundle exec rails db:create || true

echo "Rodando migrations no ambiente de teste..."
RAILS_ENV=test bundle exec rails db:migrate

# Iniciar servidor Rails
echo "Iniciando servidor Rails..."
exec bundle exec rails server -b 0.0.0.0
