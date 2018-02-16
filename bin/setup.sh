#!/bin/bash

if [ -f "./wordpress/wp-config.php" ]; then
	echo "WordPress config file found."
	exit 1
fi

echo "WordPress config file not found. Installing..."
docker-compose exec --user www-data phpfpm wp core download
docker-compose exec -T --user www-data phpfpm wp core config

# Ask for the site name
echo -n "Enter the site title and press [ENTER]: "
read TITLE

# Ask for the user name
echo -n "Enter your username and press [ENTER]: "
read ADMIN_USER

# Ask for the user email
echo -n "Enter your email and press [ENTER]: "
read ADMIN_EMAIL

# Ask for the password
echo -n "Enter your password and press [ENTER]: "
read ADMIN_PASSWORD

# Install WordPress
docker-compose exec --user www-data phpfpm wp db create
docker-compose exec --user www-data phpfpm wp core install --url=localhost --title="$TITLE" --admin_user="$ADMIN_USER" --admin_email=$ADMIN_EMAIL --admin_password=$ADMIN_PASSWORD

# Adjust settings
docker-compose exec --user www-data phpfpm wp rewrite structure "/%postname%/"

# Ask to remove default content ?
echo -n "Do you want to remove the default content? [y/n]"
read REMOVE_DEFAULT_CONTENT

if [ "y" = $REMOVE_DEFAULT_CONTENT ]
then
	# Remove all posts, comments, and terms
	docker-compose exec --user www-data phpfpm wp site empty --yes

	# Remove plugins and themes
	docker-compose exec --user www-data phpfpm wp plugin delete hello
	docker-compose exec --user www-data phpfpm wp plugin delete akismet
	docker-compose exec --user www-data phpfpm wp theme delete twentyfifteen
	docker-compose exec --user www-data phpfpm wp theme delete twentysixteen

	# Remove widgets
	docker-compose exec --user www-data phpfpm wp widget delete recent-posts-2
	docker-compose exec --user www-data phpfpm wp widget delete recent-comments-2
	docker-compose exec --user www-data phpfpm wp widget delete archives-2
	docker-compose exec --user www-data phpfpm wp widget delete search-2
	docker-compose exec --user www-data phpfpm wp widget delete categories-2
	docker-compose exec --user www-data phpfpm wp widget delete meta-2
fi

# Ask to install Monster Widget plugin
echo -n "Do you want to install the Monster Widget plugin? [y/n]"
read INSTALL_MONSTER_WIDGET

if [ "y" = $INSTALL_MONSTER_WIDGET ]
then
	docker-compose exec --user www-data phpfpm wp plugin install monster-widget --activate
	docker-compose exec --user www-data phpfpm wp widget add monster sidebar-1
fi

# Install additional plugins
docker-compose exec --user www-data phpfpm wp plugin install developer --activate

echo "Installation done."
echo "------------------"
echo "Username: $ADMIN_USER"
echo "Password: $ADMIN_PASSWORD"
open http://localhost/wp-login.php
