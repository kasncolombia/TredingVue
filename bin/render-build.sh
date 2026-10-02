#!/usr/bin/env bash
set -o errexit

echo "====== INSTALANDO DEPENDENCIAS ======"
bundle install

echo "====== PREPARANDO BASE DE DATOS Y MIGRACIONES ======"
bundle exec rails db:migrate
bundle exec rails db:prepare

echo "====== CARGANDO SEEDS ======"
bundle exec rails db:seed

echo "====== PRECOMPILANDO ASSETS ======"
bundle exec rails assets:precompile

echo "====== BUILD COMPLETADO ======"