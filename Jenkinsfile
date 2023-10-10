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
            name 'LOCKFILE'
            values 'rails-6.1', 'rails-7.0', 'Gemfile.lock'
          }
        }
        stages {
          stage('Build') {
            steps {
              sh "docker-compose build --pull --build-arg RUBY_VERSION=${RUBY_VERSION} --build-arg BUNDLE_LOCKFILE=${LOCKFILE} test"
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
