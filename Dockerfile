FROM instructure/rvm
MAINTAINER Instructure

WORKDIR /usr/src/app
# Everyone use the same bundler version
RUN /bin/bash -l -c "rvm use 2.5 && gem install bundler"
RUN /bin/bash -l -c "rvm use 2.6 && gem install bundler"
RUN /bin/bash -l -c "rvm use --default 2.7 && gem install bundler"

COPY --chown=docker:docker paul_bunyan.gemspec Gemfile /usr/src/app/
COPY --chown=docker:docker lib/paul_bunyan/version.rb /usr/src/app/lib/paul_bunyan/
RUN /bin/bash -l -c "bundle install"

COPY --chown=docker:docker . /usr/src/app
CMD /bin/bash -l -c "wwtd --parallel"
