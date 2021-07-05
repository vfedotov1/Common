######################################################################################################
# Скрипт выполняет бэкап бд Openldap в кластере k8s в ldif file с помощью LDAPSEARCH                 #
# Так же создается скрипт restore_ldapsearch_ldap_backup_*.sh для рестора бд ldap с помощью  LDAPADD #
#                                                                                                    #
# Добавлять скрипт в кронтаб след. образом:                                                          #
# 0 23 * * * /root/backup_restore_OpenLdap_k8s.sh ldap /tmp/ldap_backup &>/tmp/ldap_backup.log       #
# где,                                                                                               #
# ldap - namespace, где создан openldap                                                              #
# /tmp/ldap_backup - директория куда будут складываться файлы бэкапа и скрипты рестора               #
######################################################################################################


## Dynamic variables ##
namespace=$1
backup_share=$2
#######################

## Static variables ###
time_of_backup=$(date +"%d_%m_%Y__%H_%M_%S")
retention_period=365
ldap_admin_password=$(kubectl get secret -n $namespace openldap -o jsonpath="{.data.LDAP_ADMIN_PASSWORD}" | base64 --decode; echo)
ldap_pod=$(kubectl get pods -n $namespace | awk {'print $1}' | grep -v NAME)
DIT=$(kubectl exec -ti $ldap_pod -n $namespace -- /bin/bash -c "ldapsearch -x -b '' -s base '(&)' namingContexts -LLL | grep namingContexts: | sed 's/^.*: //'")
#######################

# 1. backup ldap database to ldif file
echo "backin up ldap database to ldif file"
kubectl exec -ti $ldap_pod -n $namespace -- /bin/bash -c "ldapsearch -D "cn=admin,$DIT" -w $ldap_admin_password -b "$DIT" -LLL > ldapsearch_ldap_backup.ldif" && echo "SUCCESS"  || { echo 'backup ldap database to ldif file FAILED' ; exit 1; }

# 2. copy ldif backup file from pod to backup share
if [ -d $backup_share ]
then
echo "Directory $backup_share exist"
echo "Copying ldif backup file from pod $ldap_pod to $backup_share"
kubectl cp $namespace/$ldap_pod:ldapsearch_ldap_backup.ldif $backup_share/ldapsearch_ldap_backup_$time_of_backup.ldif && echo "SUCCESS" || { echo 'FAILED' ; exit 1; }
echo "Removing ldif backup files that older than $retention_period days"
find $backup_share -type f -mtime +$retention_period -exec rm -vf {} \; && echo "SUCCESS" || { echo 'FAILED' ; exit 1; }
else
echo "Directory $backup_share does not exist, please check mountpoint"
fi

# 3. Create restore script for created backup file
echo "Creating restore script $backup_share/ldapsearch_ldap_backup_${time_of_backup}_restore.sh"
cat <<EOT >$backup_share/ldapsearch_ldap_backup_${time_of_backup}_restore.sh && echo "SUCCESS" || { echo 'FAILED' ; exit 1; }
# Скрипт восстановления бд Openldap в кластере k8s c помощью LDAPADD
# Необходимо положить след. 2 файла в одну директорию и выполнить данный скрипт на мастер ноде K8S:
# 1) ldapsearch_ldap_backup_02_07_2021__14_40_51.ldif
# 2) ldapsearch_ldap_backup_02_07_2021__14_40_51_restore.sh
# Примечание:
# - У каждого ldapsearch_ldap_backup_ВРЕМЯ_ВЫПОЛНЕНИЯ_БЭКАПА.ldif файла есть свой ldapsearch_ldap_backup_ВРЕМЯ_ВЫПОЛНЕНИЯ_БЭКАПА_restore.sh
# - Т.е. можно выполнять рестор из директории, где множество файлов *backup*.ldif, т.к. имя ldif файла специально захардкоржено по времени в каждом *restore.sh скрипте.
#
# Пример запуска ЭТОГО скрипта уже с учетом имени файлов:
# #################################################################################################
# mkdir -p /tmp/restore_ldap_dir
# ls -l /tmp/restore_ldap_dir
# -rw-r--r--. 1 root root 2669 Jul  1 20:05 ldapsearch_ldap_backup_$time_of_backup.ldif
# -rwxr-xr-x. 1 root root 2540 Jul  1 20:09 ldapsearch_ldap_backup_${time_of_backup}_restore.sh
# cd /tmp/restore_ldap_dir
# chmod +x ldapsearch_ldap_backup_${time_of_backup}_restore.sh
# ./ldapsearch_ldap_backup_${time_of_backup}_restore.sh
# #################################################################################################
# Перед запуском скрипт запросит подтверждение восстановления и выбрать:
# 1. Restore с удалением текущей бд
# 2. Restore без удаления текущей бд

## Static variables ###
namespace=\${kubectl get namespaces | grep -i ldap | awk '{print $1}'}
current_location=\$(pwd)
ldap_admin_password=\$(kubectl get secret -n \$namespace openldap -o jsonpath="{.data.LDAP_ADMIN_PASSWORD}" | base64 --decode; echo)
ldap_pod=\$(kubectl get pods -n \$namespace | awk {'print \$1}' | grep -v NAME)
DIT=\$(kubectl exec -ti \$ldap_pod -n \$namespace -- /bin/bash -c "ldapsearch -x -b '' -s base '(&)' namingContexts -LLL | grep namingContexts: | sed 's/^.*: //'")
#######################

function exiting () {
        echo "Выход..."
        cd \$current_location
        }

function restore_with_delete() {
                if [ -f \$current_location/ldapsearch_ldap_backup_${time_of_backup}.ldif ]
                then
                echo "File \$(ls -l \$current_location/ldapsearch_ldap_backup_${time_of_backup}.ldif) exist"
                echo "Deleting current ldap database \$DIT"
                kubectl exec -ti \$ldap_pod -n \$namespace -- /bin/bash -c "ldapdelete -v -D "cn=admin,\$DIT" -w \$ldap_admin_password -r "\$DIT"" || { echo 'unable to delete ldap database' ; exit 1; }
                echo "Copying ldif file to pod"
                kubectl cp \$current_location/ldapsearch_ldap_backup_${time_of_backup}.ldif \$namespace/\$ldap_pod:ldapsearch_ldap_backup_${time_of_backup}.ldif
                echo "Restoring ldap database from ldif file"
                kubectl exec -ti \$ldap_pod -n \$namespace -- /bin/bash -c "ldapadd -x -D "cn=admin,\$DIT" -w \$ldap_admin_password -f ldapsearch_ldap_backup_${time_of_backup}.ldif -v" || { echo 'unable to restore ldap database' ; exit 1; }
                else
                echo "There is no ldif restore file (\$current_location/ldapsearch_ldap_backup_${time_of_backup}.ldif) in the \$current_location"
                fi
}

function restore_without_delete() {
                if [ -f \$current_location/ldapsearch_ldap_backup_${time_of_backup}.ldif ]
                then
                echo "File \$(ls -l \$current_location/ldapsearch_ldap_backup_${time_of_backup}.ldif) exist"
                echo "Copying ldif file to pod"
                kubectl cp \$current_location/ldapsearch_ldap_backup_${time_of_backup}.ldif \$namespace/\$ldap_pod:ldapsearch_ldap_backup_${time_of_backup}.ldif
                echo "Restoring ldap database from ldif file"
                kubectl exec -ti \$ldap_pod -n \$namespace -- /bin/bash -c "ldapadd -x -D "cn=admin,\$DIT" -w \$ldap_admin_password -f ldapsearch_ldap_backup_${time_of_backup}.ldif -v" || { echo 'unable to restore ldap database' ; exit 1; }
                else
                echo "There is no ldif restore file (\$current_location/ldapsearch_ldap_backup_${time_of_backup}.ldif) in the \$current_location"
                fi
}

function choise1() {
echo -e "\n\nВы уверены что хотите продолжить восстановление ldap файла?: \n1. Продолжить восстановление удалив текущую бд ldap; \n2. Восстановить бд с нуля; ; \n3. Выход; \n\nYour choise is?"
read choise
case \$choise in
1)
        restore_with_delete;;
2)
        restore_without_delete;;
3)
        exiting;;
esac
}

        {
        choise1
        }
EOT

# 4. Send zabbix status (UNCOMMECT IF YOU NEED TO MONITOR BACKUP)

# 4.1 Set static variables
status_from_log_file=$(tail -1 $(crontab -l | grep backup_restore_OpenLdap_k8s.sh | awk '{print $9}' | sed 's/^.*>//'))

# 4.2 Check status from the log file and send the info to zabbix
echo -e "\n=====================\nSending status to zabbix:\n"
if [ "$status_from_log_file" != "SUCCESS" ]; then
        [[ -z $(which zabbix_sender) ]] || $(which zabbix_sender) -c /etc/zabbix/zabbix_agentd.conf -k 'trap[ldap_backup,result]' -o 1
else
        [[ -z $(which zabbix_sender) ]] || $(which zabbix_sender) -c /etc/zabbix/zabbix_agentd.conf -k 'trap[ldap_backup,result]' -o 0
fi
echo "====================="
