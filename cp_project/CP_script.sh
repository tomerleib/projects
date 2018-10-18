#!/usr/bin/env bash

# 1st part: simulate the environment from directories/files
# 2nd part: We will search all the files for those who have the values: Production and use them for searching over branch id
# 3rd part: mysql commands

RAND()
{
    cat /dev/urandom | tr -dc '0-9' | fold -w 256 | head -n 1 | head --bytes 4
    }

# Creating files and folders
mkdir project && cd project
DIRECTORIES=$(mkdir -p simulation/{1..999} | ls simulation)
for D in $DIRECTORIES; do
     printf "This is Production\n<value>2.23.3-RELEASE-b$( RAND )</value>\n" > simulation/$D/file.xml
done

PROD_BUILDS=$(grep -r -l "Production" simulation/)
for BUILD in $PROD_BUILDS; do
    BRANCH_ID=$(cat $BUILD | awk 'match($0, /b[0-9]*/){print substr($0, RSTART,RLENGTH) }')
    RELEASE_DATE=$(stat -c %y $BUILD| awk '{print $1}')
    printf "\nBranch $BRANCH_ID was deployed to Production at $RELEASE_DATE\n" >> ~/Desktop/production_builds
done

# mysql part (I don't have all the details such as creds, but this is how it will be basically):
## run the container
docker run -it -d -p 3306:3306 mysql
## import the DB
mysql -h localhost -udb_user -p'db_password' my_db < mydb.sql
## run the query
mysql -hlocalhost -udb_user -p'db_password'
> USE my_db;
> SELECT * FROM employees ORDER BY employee_id DESC, salary DESC;
