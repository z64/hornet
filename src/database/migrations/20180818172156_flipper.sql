-- +micrate Up
-- SQL in section 'Up' is executed when this migration is applied
create table flipper_settings (
  id serial primary key,
  feature_name text not null,
  guild_id bigint not null,
  enabled bool not null default false,
  unique (feature_name, guild_id)
);

-- +micrate Down
-- SQL section 'Down' is executed when this migration is rolled back
drop table flipper_settings;
