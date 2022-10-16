#!/bin/bash -e

cd /srv/makina-maps

cd openmaptiles && docker-compose -f docker-compose.yml -f ../docker-compose.openmaptiles.additional.yml up -d postgres postserve && cd ..
./dc up -d

