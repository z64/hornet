require "./hornet"

Hornet.configure_plugins if File.exists?("config.json")
Hornet.run(ARGV)
