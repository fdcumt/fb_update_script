#!/bin/sh


update_mysql_69() 
{
	mysqldump -h127.0.0.1 -uroot -psanguoxx4321 --port=3306 -d -R --database blood001 > blood.sql 
	sed -i 's/blood001/blood004/g' blood.sql 
	mysql -h122.11.50.69 --port=3306 -uroot -psanguoxx4321 -e "source blood.sql;"
	rm -rf blood.sql 
}

update_mysql_4416() 
{
	mysqldump -h127.0.0.1 -uroot -psanguoxx4321 --port=3306 -d -R --database blood001 > blood.sql 
	sed -i 's/blood001/blood002/g' blood.sql 
	mysql -h127.0.0.1 --port=4416 -uroot -psanguoxx4321 -e "source blood.sql;"
	rm -rf blood.sql 
}

help() 
{
	echo '[69|4416]'
}

main() 
{
    case "$1" in 
		69) update_mysql_69;;
		4416) update_mysql_4416;;
		help) help;;
	esac
} 


main $1 $2 $3


