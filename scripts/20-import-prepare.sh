#!/bin/bash

set -e

DC_OPTS="--rm -u $(id -u):$(id -g)"

export PROVIDER=${PROVIDER:-geofabrik}
export AREA=${1:-andorra}
export DIFF_MODE=${DIFF_MODE:-true}

# Providers such as openstreetmap.fr use hierarchical area IDs (e.g. "africa/ethiopia").
# openmaptiles-tools download-osm preserves that hierarchy in the output path, but
# the importer only looks for *.osm.pbf files directly in ./data.  So we keep a
# short, flat basename for all generated files.
BASENAME="${AREA##*/}"
PBF_FILE="./data/${BASENAME}.osm.pbf"
REPL_FILE="./data/${BASENAME}.repl.json"
BBOX_FILE="./data/${BASENAME}.bbox"

# Remove any other OSM extracts (and their companion config/bbox files) so that
# OpenMapTiles auto-detects the area we are preparing.
while IFS= read -r -d '' pbf; do
    echo "Removing stale extract ${pbf}"
    rm -f "${pbf}"
    base="${pbf%.osm.pbf}"
    rm -f "${base}.repl.json" "${base}.bbox"
    # Remove now-empty parent directories created for hierarchical area names.
    dir="$(dirname "${pbf}")"
    if [[ "${dir}" != "./data" ]]; then
        rmdir "${dir}" 2>/dev/null || true
    fi
done < <(find ./data -name '*.osm.pbf' -not -path "${PBF_FILE}" -print0)

if test -f "${PBF_FILE}"; then
    if [[ "${DIFF_MODE}" == "true" && ! -f "${REPL_FILE}" ]]; then
        echo "WARN: ${PBF_FILE} exists but ${REPL_FILE} is missing."
        echo "      Delete the extract and re-run prepare to regenerate the replication config."
        exit 1
    fi
    echo "${PBF_FILE} already exists, skip download."
    exit
fi

# Remove OpenStreetMap diff state from a previous run.
make init-dirs
docker-compose run ${DC_OPTS} openmaptiles-tools bash -c "rm -fr /import/??? /import/borders /import/expire_tiles"
mkdir -p data/expire_tiles

# Download the extract (and, in DIFF_MODE, the matching imposm replication config).
make download-${PROVIDER} area="${AREA}"

# If the provider laid the files out hierarchically, flatten them.
PBF_NESTED="./data/${AREA}.osm.pbf"
REPL_NESTED="./data/${AREA}.repl.json"
BBOX_NESTED="./data/${AREA}.bbox"
if [[ -f "${PBF_NESTED}" && "${PBF_NESTED}" != "${PBF_FILE}" ]]; then
    echo "Flattening hierarchical output from ${AREA} to ${BASENAME}"
    mv "${PBF_NESTED}" "${PBF_FILE}"
    [[ -f "${REPL_NESTED}" ]] && mv "${REPL_NESTED}" "${REPL_FILE}"
    [[ -f "${BBOX_NESTED}" ]] && mv "${BBOX_NESTED}" "${BBOX_FILE}"
    rmdir "$(dirname "${PBF_NESTED}")" 2>/dev/null || true
fi

echo "Prepared ${BASENAME} extract: ${PBF_FILE}"
if [[ "${DIFF_MODE}" == "true" ]]; then
    echo "Replication config: ${REPL_FILE}"
fi
