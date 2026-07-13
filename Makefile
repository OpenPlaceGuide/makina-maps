# Root Makefile for Makina Maps.
# Wraps the OpenMapTiles Makefile and the import/update scripts so that the
# whole stack can be driven from the project root without repeated `cd`.
#
# Typical workflow for Ethiopia with openstreetmap.fr minutely updates:
#
#   make prepare provider=osmfr area=africa/ethiopia
#   make import
#   make up        # start postserve + tileserver
#   make update    # (re)apply pending minutely diffs
#

OMT_DIR := openmaptiles

PROVIDER ?= geofabrik
area     ?= andorra

.PHONY: help
help:
	@echo "Makina Maps - available make targets"
	@echo ""
	@echo "Data preparation & import (run from project root):"
	@echo "  make prepare PROVIDER=osmfr area=africa/ethiopia   download extract + repl config"
	@echo "  make import                                         import the prepared extract"
	@echo "  make update                                         apply pending OSM updates"
	@echo ""
	@echo "Server control:"
	@echo "  make up                                             start DB, postserve and tile server"
	@echo "  make down                                           stop the tile server and DB"
	@echo "  make destroy-db                                     destroy the DB and its volumes"
	@echo ""
	@echo "Pass-through helpers to the OpenMapTiles Makefile:"
	@echo "  make psql                                           open a PostgreSQL console"
	@echo "  make list-geofabrik                                 list downloadable Geofabrik areas"
	@echo ""

.PHONY: prepare
prepare:
	@(cd $(OMT_DIR) && PROVIDER=$(PROVIDER) ../scripts/20-import-prepare.sh "$(area)")

.PHONY: import
import:
	@(cd $(OMT_DIR) && ../scripts/30-import-extract.sh)

.PHONY: update
update:
	@(cd $(OMT_DIR) && ../scripts/40-update.sh)

.PHONY: up
up:
	$(MAKE) -C $(OMT_DIR) start-db
	cd $(OMT_DIR) && docker-compose up -d postserve
	docker-compose up -d

.PHONY: down
down:
	docker-compose down
	$(MAKE) -C $(OMT_DIR) stop-db

.PHONY: destroy-db
destroy-db:
	$(MAKE) -C $(OMT_DIR) destroy-db

.PHONY: psql
psql:
	$(MAKE) -C $(OMT_DIR) psql

.PHONY: list-geofabrik
list-geofabrik:
	$(MAKE) -C $(OMT_DIR) list-geofabrik
