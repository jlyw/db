#!/bin/bash
### Set Language
TEXTDOMAIN=db

### User Parameters
mysql_user='root'
mysql_password=''

### Variables
user_has_set_mysql_password=false

### CONSTRUCT
function construct {
	if ! type mysql >/dev/null 2>&1; then
		echo "You need to install Mysql to continue."
		echo "Try 'sudo apt-get install mysql-server'."
		exit
	fi

	if [[ $mysql_user != 'root' ]]; then
		echo "Please set 'root' as mysql_user at line 6 to continue."
		exit
	fi

	if [[ $mysql_password == '' ]]; then
		read -s -p "Enter your mysql root password: " mysql_password
		echo ""

		while [[ $mysql_password == '' ]]; do
			construct
		done

		user_has_set_mysql_password=true
	fi

	if [[ `mysql -u $mysql_user --password=$mysql_password -e "SHOW databases" 2>&1 | grep -v "[Warning]"` ]]; then
		if $user_has_set_mysql_password; then
			printf "$(tput setaf 2)Mysql $mysql_user password set!$(tput sgr 0)\n\n"
		fi
	else
		printf "$(tput setaf 3)WARN: incorrect password.$(tput sgr 0)\n"

		mysql_password='' # Avoid infinite loop
		
		construct
	fi

	echo "Welcome to Database Manager for Mysql!"

	chooseAction
}

### CHOOSE ACTION
function chooseAction {
	echo ""
	echo "Available actions:"
	echo "    1/ List available databases"
	echo " "

	read -p "Choose an action: " action_number

	case $action_number in
		1 )
			actionListDatabases
			exit
			;;
		* )
			echo "$(tput setaf 3)WARN : incorrect action$(tput sgr 0)"
			echo " "
			chooseAction
			;;
	esac
}

### LIST AVAILABLE DATABASES
function actionListDatabases {
	echo "List of databases"
}

### Check arguments
construct
exit