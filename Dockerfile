FROM instructure/rvm
MAINTAINER Instructure

WORKDIR /usr/src/app
RUN /bin/bash -l -c "rvm use --default 2.3"

COPY paul_bunyan.gemspec Gemfile /usr/src/app/
COPY lib/paul_bunyan/version.rb /usr/src/app/lib/paul_bunyan/

USER root
RUN chown -R docker:docker /usr/src/app
USER docker
RUN /bin/bash -l -c "bundle install"

COPY . /usr/src/app
USER root
RUN chown -R docker:docker /usr/src/app/*
USER docker
CMD /bin/bash -l -c "wwtd --parallel"
