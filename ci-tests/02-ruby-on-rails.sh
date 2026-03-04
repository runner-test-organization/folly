#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
JOBS="$(nproc)"
WORKDIR="${WORKDIR:-$HOME/ci-rails}"
RAILS_REF="${RAILS_REF:-v8.0.1}"

git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# Now install
rbenv install 3.2.6
rbenv global 3.2.6

ruby -e 'abort "Need Ruby >= 3.2" unless RUBY_VERSION >= "3.2"'

mkdir -p "${WORKDIR}" && cd "${WORKDIR}"
git clone --depth 1 --branch "${RAILS_REF}" https://github.com/rails/rails.git
cd rails

gem install bundler --no-document --user-install
export PATH="$(ruby -e 'puts Gem.user_dir')/bin:$PATH"

bundle config set path vendor/bundle
bundle config set without "docs"
bundle config set jobs "${JOBS}"
BUNDLE_GEMFILE=Gemfile bundle lock --update google-protobuf
bundle install

for fw in actionview actionmailbox actionmailer activejob; do
  echo "=== Testing $fw ==="
  (cd "$fw" && PARALLEL_WORKERS=$(nproc) bundle exec rake test)
done