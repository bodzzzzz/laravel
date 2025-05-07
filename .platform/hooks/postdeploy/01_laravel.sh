#!/bin/bash
set -e # Exit immediately if any command fails
echo "[POSTDEPLOY] Starting post-deployment tasks..."

cd /var/app/current

# Environment Setup
echo "[POSTDEPLOY] Setting up environment..."
if [ ! -f .env ]; then
    echo "[POSTDEPLOY] Copying .env.prod to .env..."
    cp .env.prod .env
else
    echo "[POSTDEPLOY] .env already exists."
fi

# Secure Permissions (more restrictive)
echo "[POSTDEPLOY] Setting permissions..."
mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache
touch storage/logs/laravel.log

# Set owner to webapp if exists, otherwise use default
if id "webapp" &>/dev/null; then
    sudo chown -R webapp:webapp storage bootstrap/cache
else
    sudo chown -R $(whoami):$(whoami) storage bootstrap/cache
fi

chmod -R 775 storage bootstrap/cache
chmod 664 storage/logs/laravel.log

# APP_KEY Generation (fixed logic)
echo "[POSTDEPLOY] Checking APP_KEY..."
if ! grep -q '^APP_KEY=base64:' .env; then
    echo "[POSTDEPLOY] Generating new APP_KEY..."
    php artisan key:generate --force
else
    echo "[POSTDEPLOY] Valid APP_KEY exists, skipping generation."
fi

# Cache and Optimization
echo "[POSTDEPLOY] Optimizing application..."
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan optimize

# Database Migration
echo "[POSTDEPLOY] Running database migrations..."
php artisan migrate --force

# Optional: Seed only in specific environments
if [ "$APP_ENV" = "staging" ] || [ "$APP_ENV" = "production" ]; then
    echo "[POSTDEPLOY] Running database seeds..."
    php artisan db:seed --force
fi

echo "[POSTDEPLOY] Post-deployment tasks completed successfully."
exit 0
