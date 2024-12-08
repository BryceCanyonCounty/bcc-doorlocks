fx_version "cerulean"
games {"rdr3"}
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

lua54 "yes"

author 'BCC Team'

description 'Create doors for exiting houses in RedM!'

shared_scripts {
  "config.lua",
  "locale.lua",
  "languages/*.lua"
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  '/server/dbUpdater.lua',
  '/server/API.lua',
  "/server/server.lua"
}

client_scripts {
  "/client/functions.lua",
  "/client/client.lua",
  "/client/doorhashes.lua",
  '/client/MenuSetup.lua'
}

dependency {
  'vorp_core',
  'vorp_inventory',
  'vorp_character',
  'feather-menu',
  'bcc-utils',
  'bcc-minigames'
}

version '1.1.1'
