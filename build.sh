#!/bin/bash

set -e

docker-compose build --pull test
docker-compose run test
