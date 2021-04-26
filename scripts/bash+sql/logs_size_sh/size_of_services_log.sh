#!/bin/bash
date=$(date --date="yesterday" +"%F")
list_of_directories_gz=/home/fusion/logs_size_sh/list_of_directories_gz
list_of_directories_file=/home/fusion/logs_size_sh/list_of_directories_file

send_mail() {
cat <<EOF - ${1} | /usr/sbin/sendmail -t
To: ${3}
From: fusion@service_server.home.local
Subject: ${2}
Content-Type: text/html
EOF
}

rm -rf /tmp/Size_of_services_log_error.log
rm -rf /tmp/Size_of_services_log.log

echo "Подсчет объема логов сервисов СТЕНДА за $date в mb"
echo -e "SERVICE_NAME\nGROWTH_IN_MB_PER_DAY" > /tmp/Size_of_services_log.log
cat $list_of_directories_gz | while read LINE; do echo "$LINE/$date" >> /tmp/Size_of_services_log.log; zcat $LINE/$date*/* | wc -c | awk '{for (i = 1; i <= NF; i++) $i = ($i/(1024*1024)); print }' >> /tmp/Size_of_services_log.log; done >> /tmp/Size_of_services_log.log 2>>/tmp/Size_of_services_log_error.log
cat $list_of_directories_file | while read LINE; do echo "$LINE/$date" >> /tmp/Size_of_services_log.log; du -sb $LINE/$date* | awk '{total +=$1};END {print total/1024/1024}' >> /tmp/Size_of_services_log.log; done >> /tmp/Size_of_services_log.log 2>>/tmp/Size_of_services_log_error.log

##########################################HARDCODE *sad_smile* #######################################################
#plus identical services sizes
#XAI
XAI_PLUS_1=$(grep -ws "XAI" /tmp/Size_of_services_log.log -A 1 | grep -v "XAI" | grep -Eo '[0-9]{1,9}' | head -n 1)
XAI_PLUS_2=$(grep -ws "XAI_" /tmp/Size_of_services_log.log -A 1 | grep -v "XAI_" | grep -Eo '[0-9]{1,9}' | head -n 1)
TOTAL_XAI=$(($XAI_PLUS_1+$XAI_PLUS_2))
sed -i "s/${XAI_PLUS_2}/${TOTAL_XAI}/g" /tmp/Size_of_services_log.log
#XAIMASS
XAIMASS_PLUS_1=$(grep -ws "XAIMASS" /tmp/Size_of_services_log.log -A 1 | grep -v "XAIMASS" | grep -Eo '[0-9]{1,9}' | head -n 1)
XAIMASS_PLUS_2=$(grep -ws "XAIMASS_" /tmp/Size_of_services_log.log -A 1 | grep -v "XAIMASS_" | grep -Eo '[0-9]{1,9}' | head -n 1)
TOTAL_XAIMASS=$(($XAIMASS_PLUS_1+$XAIMASS_PLUS_2))
sed -i "s/${XAIMASS_PLUS_2}/${TOTAL_XAIMASS}/g" /tmp/Size_of_services_log.log

#delete unneeded rows that already stacked with other values
sed -i -e '/\/sgm\/logs\/XAI\//,+1d' /tmp/Size_of_services_log.log
sed -i -e '/\/sgm\/logs\/XAIMASS\//,+1d' /tmp/Size_of_services_log.log

#replace each row to service's name
# sed -i '\/sgm\/logs\/weblogic\/AdminServer\/2020-10-05_20-00\/\*/c\AdminServer' /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/weblogic\/AdminServer\/${date}/c\AdminServer" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/weblogic\/BIP10_\*\/${date}/c\BIP10_server" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/weblogic\/bi_\*\/${date}/c\bi_server" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/weblogic\/CCB_\*\/${date}/c\CCB_server" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/weblogic\/ODI_\*\/${date}/c\ODI_server" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/weblogic\/WEB_\*\/${date}/c\WEB_server" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/weblogic\/XAIMASS_\*\/${date}/c\XAIMASS_server" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/weblogic\/XAI_\*\/${date}/c\XAI_server" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/ccbhome_\*\/${date}/c\ccbhome" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs\/ohs_inst\*\/${date}/c\ohs_inst" /tmp/Size_of_services_log.log
sed -i "\/sgm\/logs_wsdl\/CompanyCCBWeb\*\/log\/wsdl\/${date}/c\logs_wsdl" /tmp/Size_of_services_log.log
######################################################################################################################

#formating /tmp/Size_of_services_log.log for txt_to_html.sh ##print first row with second row and etc.
awk ORS=NR%2\?FS:RS /tmp/Size_of_services_log.log |& tee /tmp/Size_of_services.log

#rm previos html file
rm -rf /tmp/growth.html

#converting txt /tmp/Size_of_services.log to html file
/home/fusion/logs_size_sh/txt_to_html.sh /tmp/Size_of_services.log /tmp/growth.html "Размер логов за ${date}"

#create the following "table_growth.sql" sql script in the source server:
###########################################################################################
#set newpage 0 verify off feedback off echo off term off trimout on trimspool on timing off;
#set lines 150;
#col OWNER for a20;
#col TABLE_NAME for a30;
#SPOOL /tmp/table_growth.tmp
#select OWNER,TABLE_NAME,TABLE_SIZE,GROWTH_IN_MB_PER_DAY from system.table_growth where TO_CHAR(time, 'YYYYMMDD') = TO_CHAR(SYSDATE-1, 'YYYYMMDD') ORDER BY owner;
#spool off;
###########################################################################################

#run sql script in the remote server to spool table data
ssh oracle@db.domain.ru '. ./DB.env && sqlplus / as sysdba  <<EOF
@table_growth.sql
EOF'

#scp table data file
scp oracle@db.domain.ru:/tmp/table_growth.tmp /tmp/

#formating /tmp/table_growth.tmp #deleting unneeded rows
sed -i 2d /tmp/table_growth.tmp

#converting txt /tmp/Size_of_services.log to html file
/home/fusion/logs_size_sh/txt_to_html.sh /tmp/table_growth.tmp /tmp/growth.html "Прирост логов в таблицах бд DB за ${date}"

#send mail
send_mail /tmp/growth.html "ПРОЕКТ. Daily log's growth Report" user_1@mail.ru,user_2@mail.ru
