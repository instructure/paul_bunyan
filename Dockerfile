FROM instructure/ruby:2.1
MAINTAINER Instructure

COPY Gemfile* *.gemspec /usr/src/app/
COPY lib/paul_bunyan/version.rb /usr/src/app/lib/paul_bunyan/
RUN bundle install

COPY . /usr/src/app
USER root
RUN chown -R docker:docker /usr/src/app/*
USER docker
CMD ["bundle", "exec", "wwtd", "--parallel"]
