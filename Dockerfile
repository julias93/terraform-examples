# Gobal ARG

# Base container
FROM ruby:3.2.0-alpine AS base

WORKDIR /app
ENV BUNDLE_PATH vendor/bundle

RUN gem install bundler --no-document --version 2.4.0

# Builder container
FROM base AS builder

RUN apk update && apk add --no-cache --update \
    build-base \
    tzdata \
    mariadb-dev

# Install gem packages
COPY Gemfile Gemfile.lock ./
RUN bundle install \
    && rm -rf "$BUNDLE_PATH/ruby/$RUBY_VERSION/cache/*"

# Assets container
FROM builder AS assets

COPY . .
COPY --from=builder /app/$BUNDLE_PATH /app/$BUNDLE_PATH

ARG RAILS_ENV production
ARG SECRET_KEY_BASE
RUN bundle exec rails assets:precompile

# Main container
FROM base AS main

# Add your packages
RUN apk update && apk add --no-cache --update \
    tzdata \
    curl \
    mariadb-dev

COPY . .

# Copy files from each containers
COPY --from=builder /app/$BUNDLE_PATH /app/$BUNDLE_PATH
COPY --from=assets /app/public/assets /app/public/assets

CMD ["/app/command.sh"]
