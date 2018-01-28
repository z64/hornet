require "yaml"

module Hornet
  class Config
    YAML.mapping(
      token: String,
      game: String?,
      owner: UInt64
    )
  end
end
