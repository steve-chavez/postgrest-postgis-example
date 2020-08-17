#!/bin/bash

## Adapted from https://blog.jawg.io/how-to-make-mvt-with-postgis/
## When a lot of 4k size tiles get generated the process can be stopped with ctrl + c.
## TODO: Limit the above.

set -e

x0=1235
y0=1539
zoom=12

function admin() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
    SELECT encode(ST_AsMVT(q, 'admin', 4096, 'geom'), 'hex')
    FROM (
      SELECT id, name, admin_level,
        ST_AsMvtGeom(
          geometry,
          st_tileenvelope($tz, $tx, $ty),
          4096,
          256,
          true
        ) AS geom
      FROM public.osm_admin
      WHERE geometry && st_tileenvelope($tz, $tx, $ty)
      AND ST_Intersects(geometry, st_tileenvelope($tz, $tx, $ty))
    ) AS q
  ) TO STDOUT;
  "
}

function buildings() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
    SELECT encode(ST_AsMVT(q, 'buildings', 4096, 'geom'), 'hex')
    FROM (
      SELECT id, name, type,
        ST_AsMvtGeom(
          geometry,
          st_tileenvelope($tz, $tx, $ty),
          4096,
          256,
          true
        ) AS geom
      FROM public.osm_buildings
      WHERE geometry && st_tileenvelope($tz, $tx, $ty)
      AND ST_Intersects(geometry, st_tileenvelope($tz, $tx, $ty))
    ) AS q
  ) TO STDOUT;
  "
}

function amenities() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
    SELECT encode(ST_AsMVT(q, 'amenities', 4096, 'geom'), 'hex')
    FROM (
      SELECT id, name, type,
        ST_AsMvtGeom(
          geometry,
          st_tileenvelope($tz, $tx, $ty),
          4096,
          256,
          true
        ) AS geom
      FROM public.osm_amenities
      WHERE geometry && st_tileenvelope($tz, $tx, $ty)
      AND ST_Intersects(geometry, st_tileenvelope($tz, $tx, $ty))
    ) AS q
  ) TO STDOUT;
  "
}

## For testing:
#psql -tq -c "$(admin 12 1205 1539)" | xxd -r -p
#psql -tq -c "$(buildings 12 1205 1539)" | xxd -r -p
#psql -tq -c "$(amenities 12 1205 1539)" | xxd -r -p

offset=1

for (( z=$zoom; z<=16; ++z )); do
  for (( x=$x0-$offset; x<=$x0+$offset; ++x )); do
    mkdir -p ./tiles/$z/$x
    for (( y=$y0-$offset; y<=$y0+$offset; ++y )); do
      file="./tiles/$z/$x/$y.pbf"
      {
      psql -tq -c "$(admin $z $x $y)" | xxd -r -p ;
      psql -tq -c "$(buildings $z $x $y)" | xxd -r -p ;
      psql -tq -c "$(amenities $z $x $y)" | xxd -r -p ;
      } > $file
      du -h $file
    done
  done
  let "offset *= 2"
  let "x0 = x0 * 2"
  let "y0 = y0 * 2"
done
