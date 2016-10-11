FROM instructure/rvm
MAINTAINER Instructure

COPY Gemfile* *.gemspec /usr/src/app/
COPY lib/paul_bunyan/version.rb /usr/src/app/lib/paul_bunyan/

USER root
RUN chown -R docker:docker /usr/src/app
USER docker
RUN /bin/bash -l -c "cd /usr/src/app && bundle install"

COPY . /usr/src/app
USER root
RUN chown -R docker:docker /usr/src/app/*
USER docker
CMD /bin/bash -l -c "cd /usr/src/app && bundle exec wwtd --parallel"
