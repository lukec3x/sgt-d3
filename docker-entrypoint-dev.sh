#!/bin/bash
set -e

echo "=== Docker Development Entrypoint ==="
echo "DATABASE_HOST: ${DATABASE_HOST}"
echo "RAILS_ENV: ${RAILS_ENV}"

# Limpar cache do Bootsnap
echo "Limpando cache do Bootsnap..."
rm -rf tmp/cache
find tmp/pids -type f -name "*.pid" -delete 2>/dev/null || true

# Preparar banco de dados
echo "Rodando migrations..."
bundle exec rails db:migrate

# Iniciar servidor Rails
echo "Iniciando servidor Rails..."
exec bundle exec rails server -b 0.0.0.0
