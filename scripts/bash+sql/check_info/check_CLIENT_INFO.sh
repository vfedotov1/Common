#!/bin/bash
DB_ENV=DB.env
if [ -d /tmp/check_CLIENT_INFO ]
  then
  echo "Directory exist"
  else
    mkdir /tmp/check_CLIENT_INFO
    fi
    cd ~ && . ./${DB_ENV} && sqlplus / as sysdba @/tmp/check_CLIENT_INFO.sql
    cp /tmp/check_CLIENT_INFO/check_CLIENT_INFO.csv /tmp/check_CLIENT_INFO/check_CLIENT_INFO_$(date +%d_%m_%Y_%H:%M:%S).csv
