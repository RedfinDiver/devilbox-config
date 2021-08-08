#!/bin/bash
# 
# This script starts and stops the devilbox webserver for development

devilbox_dir=/home/markus/Projekte/devilbox
devilbox_cfg=/home/markus/Projekte/dotfiles/devilbox

# check for existing devilbox repo, clone it when not existing
if [ ! -d ~/Projekte/devilbox ]
then
    # clone the repo first
    git clone https://github.com/cytopia/devilbox.git ~/Projekte/devilbox
fi

# check for existing webserver desktop file
if [ ! -f ~/.local/share/applications/webserver.desktop ]
then
    # copy the desktop file
    cp webserver.desktop ~/.local/share/applications/webserver.desktop
fi

# check for running server
running=`docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' devilbox_httpd_1 2>/dev/null`

# change working directory to devilbox directory
cd $devilbox_dir

# server not running, copy all config files
if [ -z $running ]
then
    # copy configurations
    cp $devilbox_cfg/.env $devilbox_dir/.env
    cp $devilbox_cfg/xdebug.ini $devilbox_dir/cfg/php-ini-7.3/xdebug.ini
    cp $devilbox_cfg/docker-compose.override.yml $devilbox_dir/docker-compose.override.yml

    # start webserver, the first time it takes a while!
    docker-compose up -d httpd php mysql
else
    # webserver running, create mysql backups and shut down
    docker exec devilbox_php_1 sh -c 'rm -rf /shared/backups/mysql/*'
    docker exec devilbox_php_1 mysqldump-secure
    docker-compose down

    # delete copied config files
    rm $devilbox_dir/.env
    rm $devilbox_dir/cfg/php-ini-7.3/xdebug.ini
    rm $devilbox_dir/docker-compose.override.yml
fi
