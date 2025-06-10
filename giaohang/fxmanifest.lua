-- file: qb-jobcenter/fxmanifest.lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'TenBan'
description 'NPC Job Center voi chuc nang thue xe va giao hang'
version '1.0.0'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'qb-core',
    'qb-menu'
}