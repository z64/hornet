require "micrate"
require "pg"

Micrate::DB.connection_url = ENV["HORNET_DB_URL"]
Micrate::Cli.run
