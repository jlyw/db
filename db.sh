#!/bin/bash
### Set Language
TEXTDOMAIN=db

### User Parameters
mysql_user='root'
mysql_password=''

### Variables
user_has_set_mysql_password=false

### Test if value is numeric
function isNumeric {
	reg='^[0-9]+$'

	if ! [[ $1 =~ $reg ]]; then
		echo false
	else
		echo true
	fi
}

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
	echo "    2/ Delete a database"
	echo " "

	read -p "Choose an action: " action_number
	echo " "

	case $action_number in
		1 )
			actionListDatabases
			;;
		2 )
			actionDeleteDatabase
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
	listAvailableDatabases

	quitProgram
}

function listAvailableDatabases {
	mysql_db=( $(mysql -u $mysql_user --password=$mysql_password -e "SHOW databases") )

	declare -A db_list
	i=0

	for db in ${mysql_db[@]}; do
		if [[ $i == 0 ]]; then
			((i++))
		else
			if ! [[ $db == "information_schema" || $db == "mysql" || $db == "performance_schema" || $db == "sys" ]]; then
				db_list[$i]=$db
				((i++))
			fi
		fi
	done

	echo " "
	echo "Available databases"

	for db_id in ${!db_list[*]}; do
		echo "    (${db_id}) ${db_list[${db_id}]}"
	done

	echo " "
}

### QUIT PROGRAM
function quitProgram {
	read -p "Quit program ? (y/n) " quit_program

	case $quit_program in
		'y' )
			exit
			;;
		'n' )
			chooseAction
			;;
		* )
			echo "$(tput setaf 3)WARN : incorrect answer$(tput sgr 0)"
			quitProgram
			;;
	esac
}

### CONFIRM DATABASE TO DELETE
function confirmDatabaseDeletion {
	read -p "Are you sure you want to delete this database ? (y/n) " confirm_delete_db

	case $confirm_delete_db in
		n|y )
			shift
			;;
		* )
			echo "$(tput setaf 3)WARN : incorrect answer$(tput sgr 0)"
			confirmDatabaseDeletion
			;;
	esac

	echo $confirm_delete_db
}

### DELETE DATABASE
function actionDeleteDatabase {
	mysql_db=( $(mysql -u $mysql_user --password=$mysql_password -e "SHOW databases") )

	declare -A db_list
	i=0

	for db in ${mysql_db[@]}; do
		if [[ $i == 0 ]]; then
			((i++))
		else
			if ! [[ $db == "information_schema" || $db == "mysql" || $db == "performance_schema" || $db == "sys" ]]; then
				db_list[$i]=$db
				((i++))
			fi
		fi
	done

	echo " "
	echo "Available databases"

	for db_id in ${!db_list[*]}; do
		echo "    (${db_id}) ${db_list[${db_id}]}"
	done

	echo " "

	read -p "Database ID to delete: " db_id_to_delete

	echo " "

	while [[ ${db_list[${db_id_to_delete}]} == "" || ($(isNumeric $db_id_to_delete) == false) ]]; do
		printf "$(tput setaf 3)WARN: incorrect database id.$(tput sgr 0)\n"
		read -p "Database ID to delete: " db_id_to_delete
	done

	echo "Database ${db_list[${db_id_to_delete}]} selected"
	echo " "

	confirm_delete=$(confirmDatabaseDeletion)

	echo " "

	if [[ $confirm_delete == 'n' ]]; then
		echo "Task canceled"
		quitProgram
	fi

	if ! [ `mysql -u $mysql_user --password=$mysql_password -e "DROP database ${db_list["$db_id_to_delete"]}" 2>&1 | grep -v "[Warning]"` ]; then
		echo "$(tput setaf 2)Database ${db_list["$db_id_to_delete"]} has been deleted!$(tput sgr 0)"
	else
		echo "$(tput setaf 1)ERR : cannot delete database ${db_list["$db_id_to_delete"]}.$(tput sgr 0)"
	fi
	
	echo " "
	quitProgram
}

construct