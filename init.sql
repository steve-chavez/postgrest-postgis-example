begin;

create extension if not exists postgis;

-- data taken from http://duspviz.mit.edu/tutorials/intro-postgis.php
CREATE TABLE coffee_shops (
  id integer NOT NULL,
  name character varying(50),
  address character varying(50),
  city character varying(50),
  state character varying(50),
  zip character varying(10),
  lat numeric,
  lon numeric,
  geom geometry(point, 4326)
);

-- data taken from https://postgis.net/workshops/postgis-intro/
CREATE TABLE nyc_streets (
  gid    serial  primary key
, id     float8
, name   text
, oneway text
, "type" text
, geom   geometry(MULTILINESTRING, 26918)
);
CREATE INDEX ON nyc_streets USING GIST ("geom");

create or replace function nyc_streets_mvt(z integer, x integer, y integer) returns bytea as $$
with tile_env as (
  select st_tileenvelope(z, x, y) as res
)
select
  st_asmvt(tile)
from (
  select
    st_asmvtgeom(st_transform(geom, 3857), tile_env.res) as geom,
    name, oneway, "type"
  from nyc_streets, tile_env
  where geom && st_transform(tile_env.res, 26918)
) tile;
$$ language sql immutable parallel safe;

-- New York lat long
-- -74.006, 40.71

-- Convert to z x y on http://oms.wff.ch/calc.htm
-- Gives 12, 1205, 1540

-- Give any tile because 1205 is in bounds
-- select nyc_streets_mvt(12, 1205, 1540);

-- Doesn't give any tile because 1200 it's out of bounds
-- select nyc_streets_mvt(12, 1200, 1540);

\i data.sql

commit;