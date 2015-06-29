FROM docker.insops.net/instructure/instructure-ruby:2.1
MAINTAINER Tyler Pickett <tpickett@instructure.com>

WORKDIR /usr/src/app
COPY Gemfile* *.gemspec /usr/src/app/
COPY lib/logging/version.rb /usr/src/app/lib/logging/
RUN bundle install

COPY . /usr/src/app
USER root
RUN chown -R docker:docker /usr/src/app/*
USER docker
CMD bundle exec wwtd --parallel
