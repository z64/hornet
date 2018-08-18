module Hornet
  struct FlipperSettings
    DB.mapping(id: Int32, feature_name: String, guild_id: Int64, enabled: Bool)

    def initialize(@id : Int32, @feature_name : String, @guild_id : Int64,
                   @enabled : Bool)
    end

    def self.update(feature_name : String, guild_id : UInt64 | Discord::Snowflake,
                    enabled : Bool)
      DB.exec(<<-SQL, feature_name, guild_id, enabled)
        insert into flipper_settings
          (feature_name, guild_id, enabled) values ($1, $2, $3)
        on conflict on constraint flipper_settings_feature_name_guild_id_key
          do update set enabled = $3;
        SQL
    end

    def self.get(feature_name : String, guild_id : UInt64 | Discord::Snowflake)
      DB.query_one?(<<-SQL, feature_name, guild_id, as: FlipperSettings)
        select * from flipper_settings
        where feature_name = $1 and guild_id = $2
        SQL
    end
  end
end
