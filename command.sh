#!/bin/sh

PORT=${PORT:-3000}
BINDING=${BINDING:-0.0.0.0}

bundle exec rails db:create db:migrate

rm -f tmp/pids/server.pid
exec bundle exec rails s -p $PORT -b $BINDING
