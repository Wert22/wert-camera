fx_version 'cerulean'
game 'gta5'

author 'Wert'
description 'wert-camera'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/*.html',
    'html/js/*.js',
    'html/css/*.css',
}


client_scripts {
	'client.lua',
} 
server_scripts {
	'server.lua',
}

lua54 'yes'