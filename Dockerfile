# Laravel + Apache (PHP 8.2)
FROM php:8.2-apache

# System deps
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libjpeg-dev libfreetype6-dev libonig-dev \
    libxml2-dev libpq-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# PHP extensions (Postgres + common stuff)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install pdo pdo_pgsql gd mbstring bcmath opcache

# Apache: use /public and enable mod_rewrite
RUN a2enmod rewrite
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf \
 && sed -ri 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# Copy app
WORKDIR /var/www/html
COPY . /var/www/html

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --prefer-dist --optimize-autoloader \
 && php artisan config:clear || true

# Permissions for storage/cache
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R ug+rwx storage bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]
