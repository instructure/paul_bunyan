#!/bin/bash
rvm use ext-ruby-2.1.1-p76

bundle check || bundle install

bundle exec rspec
spec_status=$?

# this line must be last!!
exit $spec_status
