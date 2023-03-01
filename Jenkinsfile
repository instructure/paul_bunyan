#! /usr/bin/env groovy

pipeline {
  agent none

  environment {
    // Make sure we're ignoring any override files that may be present
    COMPOSE_FILE = "docker-compose.yml"
  }

  stages {
    stage('Test') {
      matrix {
        agent { label 'docker' }
        axes {
          axis {
            name 'RUBY_VERSION'
            values '2.7', '3.0', '3.1'
          }
          axis {
            name 'RAILS_VERSION'
            values '6.1', '7.0'
          }
        }
        stages {
          stage('Build') {
            steps {
              sh "docker-compose build --pull --build-arg RUBY_VERSION=${RUBY_VERSION} --build-arg BUNDLE_GEMFILE=gemfiles/rails_${RAILS_VERSION}.gemfile test"
              sh 'docker-compose run --rm test bundle exec rake'
            }
          }
        }

        post {
          cleanup {
            sh 'docker-compose down --remove-orphans --rmi all'
          }
        }
      }
    }
  }
}
