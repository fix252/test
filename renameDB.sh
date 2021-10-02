#!/bin/bash

# The tool is used to rename DB for MySQL with InnoDB engine.
# If MySQL is running with MYISAM engine, just stop MySQL > rename DB directory/folder > start MySQL.

#DB name
old="old_name"
new="new_name"

mysql -uroot -pYOUR_PASSWORD -e "create database if not exists $new DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
list_table=$(mysql -uroot -pYOUR_PASSWORD -Nse "select table_name from information_schema.TABLES where TABLE_SCHEMA='$old'")

for table in $list_table
do
    mysql -uroot -pYOUR_PASSWORD -e "rename table $old.$table to $new.$table"
done
