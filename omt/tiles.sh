#!/bin/bash

## Adapted from https://blog.jawg.io/how-to-make-mvt-with-postgis/

## This script generates mvt tiles for https://github.com/openmaptiles/openmaptiles
## Assumptions:
##  - you've loaded the opemaptiles schema with the new york pbf
##  - you can connect to the db with psql -U openmaptiles

set -e

dir=./tiles

## Zoom level coordinates

## The coordinates were obtained from the new york bbox: -83.4785061,40.0976424,-9.543467,49.873033)
## Then converted to tiles coordinates with http://oms.wff.ch/calc.htm

## Uncomment the coordinates to generate tiles for each zoom level.

## Zoom 0

#x0=0
#y0=0
#x1=0
#y1=0
#zoom=0

## Zoom 1

#x0=0
#y0=0
#x1=0
#y1=0
#zoom=1

## Zoom 2

#x0=1
#y0=1
#x1=1
#y1=1
#zoom=2

## Zoom 3

#x0=2
#y0=2
#x1=3
#y1=3
#zoom=3

## Zoom 4

#x0=4
#y0=5
#x1=7
#y1=6
#zoom=4

## Zoom 5

#x0=8
#y0=10
#x1=15
#y1=12
#zoom=5

## Zoom 6

#x0=17
#y0=21
#x1=30
#y1=24
#zoom=6

## Zoom 7

#x0=34
#y0=43
#x1=60
#y1=48
#zoom=7

## Zoom 8

#x0=68
#y0=86
#x1=121
#y1=96
#zoom=8

## Zoom 9

#x0=137
#y0=174
#x1=242
#y1=193
#zoom=9

## Zoom 10

#x0=274
#y0=347
#x1=484
#y1=387
#zoom=10

## Zoom 11

#x0=549
#y0=695
#x1=969
#y1=774
#zoom=11

## The `getmvt` function is obtained from openmaptiles/build/sql/run_last.sql. This is generated once the osm data is imported.
function omt() {
  echo "
  copy (select encode(mvt, 'hex') from getmvt($1, $2, $3)) to stdout;
  "
}

for (( x=$x0; x<=$x1; x++ )); do
  mkdir -p $dir/$zoom/$x
  for (( y=$y0; y<=$y1; y++ )); do
    file="$dir/$zoom/$x/$y.pbf"
    psql -U openmaptiles -tq -c "$(omt $zoom $x $y)" | xxd -r -p > $file
    du -h $file
  done
done
