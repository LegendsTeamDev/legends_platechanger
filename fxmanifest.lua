fx_version 'cerulean'
game 'gta5'

author 'Legends Scripts'
description 'Multi-framework Plate Changer for FiveM (QB/QBX/ESX Compatible)'
version '2.0.1'

lua54 'yes'

dependencies {
  'ox_lib'
}

optional_dependencies {
  'qbx_core',
  'qb-core',
  'es_extended'
}

shared_scripts {
  'config/*.lua',
  'shared/*.lua'
}

client_scripts {
  '@ox_lib/init.lua',
  'client/*.lua'
}

server_scripts {
  '@ox_lib/init.lua',
  "@oxmysql/lib/MySQL.lua",
  'server/*.lua'
}

files {
  'locales/*.json'
}

escrow_ignore {
  'config/*.lua',
  'locales/*.json',
  'shared/utils.lua',
}