-- +micrate Up
BEGIN;

CREATE TABLE guild_tags(
  tag_id            SERIAL PRIMARY KEY,
  guild_id          BIGINT  NOT NULL,
  owner_id          BIGINT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  name              TEXT    NOT NULL,
  locked            BOOL    NOT NULL DEFAULT true,
  content           TEXT,
  content_sanitized TEXT,
  times_used        INTEGER NOT NULL DEFAULT 0,
  UNIQUE (guild_id, name)
);

CREATE INDEX guild_tags_guild_id_owner_id_idx
          ON guild_tags (guild_id, owner_id);

CREATE INDEX guild_tags_guild_id_name_idx
          ON guild_tags (guild_id, name);

CREATE TYPE tags_action AS ENUM(
  'create',
  'edit',
  'transfer',
  'lock',
  'unlock',
  'delete'
);

CREATE TABLE guild_tags_audit_logs(
  audit_id         SERIAL      PRIMARY KEY,
  guild_tag_id     INTEGER     NOT NULL REFERENCES guild_tags (tag_id),
  action           tags_action NOT NULL,
  action_time      TIMESTAMPTZ NOT NULL DEFAULT now(),
  action_author_id BIGINT      NOT NULL,
  action_details   JSONB       NOT NULL DEFAULT '[]'::jsonb
);

COMMIT;

-- +micrate Down
BEGIN;

DROP TABLE guild_tags_audit_logs;
DROP TYPE  tags_action;
DROP TABLE guild_tags;

COMMIT;
