#!/bin/bash

set -e

docker pull docker.insops.net/instructure/instructure-ruby:2.1
docker-compose build
docker-compose run test
