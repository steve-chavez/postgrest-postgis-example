begin;

create extension postgis;

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
declare
  max numeric := 20037508.34;
  res numeric := (max*2)/(2^z);
  bbox geometry;
  mvt bytea;
begin
  bbox :=
    st_makeenvelope(
      -max + (x * res)
    , max - (y * res)
    , -max + (x * res) + res
    , max - (y * res) - res
    , 3857
    );
  select into mvt
    st_asmvt(tile)
  from (
    select
      st_asmvtgeom(st_transform(geom, 3857), bbox) as geom,
      name, oneway, "type"
    from nyc_streets
    where geom && st_transform(bbox, 26918)
  ) tile;
  return mvt;
end;
$$ language plpgsql immutable parallel safe;

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