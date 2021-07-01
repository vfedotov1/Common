######################################################################################################
# Скрипт выполняет бэкап бд Openldap в кластере k8s в ldif file с помощью LDAPSEARCH                 #
# Так же создается скрипт restore_ldapsearch_ldap_backup_*.sh для рестора бд ldap с помощью  LDAPADD #
#                                                                                                    #
# Добавлять скрипт в кронтаб след. образом:                                                          #
# * 23 * * * nohup /root/backup_ldap.sh ldap /tmp/ldap_backup &>/tmp/check_CLIENT_INFO.log &         #
# где,                                                                                               #
# ldap - namespace, где создал openldap                                                              #
# /tmp/ldap_backup - директория куда будут складываться файлы бэкапа и скрипты рестора               #
######################################################################################################


## Dynamic variables ##
namespace=$1
backup_share=$2
#######################

## Static variables ###
retention_period=365
ldap_admin_password=$(kubectl get secret -n $namespace openldap -o jsonpath="{.data.LDAP_ADMIN_PASSWORD}" | base64 --decode; echo)
ldap_pod=$(kubectl get pods -n $namespace | awk {'print $1}' | grep -v NAME)
DIT=$(kubectl exec -ti $ldap_pod -n $namespace -- /bin/bash -c "ldapsearch -x -b '' -s base '(&)' namingContexts -LLL | grep namingContexts: | sed 's/^.*: //'")
#######################

# 1. backup ldap database to ldif file
echo "backin up ldap database to ldif file"
kubectl exec -ti $ldap_pod -n $namespace -- /bin/bash -c "ldapsearch -D "cn=admin,$DIT" -w $ldap_admin_password -b "$DIT" -LLL > ldapsearch_ldap_backup.ldif"  || { echo 'backup ldap database to ldif file failed' ; exit 1; }

# 2. copy ldif backup file from pod to backup share
if [ -d $backup_share ]
then
echo "Directory $backup_share exist"
echo "Copying ldif backup file from pod $ldap_pod to $backup_share"
kubectl cp $namespace/$ldap_pod:ldapsearch_ldap_backup.ldif $backup_share/ldapsearch_ldap_backup_"$(date +"%d_%m_%Y__%H_%M_%S")".ldif
echo "Removing ldif backup files that older than $retention_period days"
find $backup_share -type f -mtime +$retention_period -exec rm -rf {} \;
else
echo "Directory $backup_share does not exist, please check mountpoint"
fi

# 3. Create restore script for created backup file
cat <<EOT >$backup_share/ldapsearch_ldap_backup_"$(date +"%d_%m_%Y__%H_%M_%S")"_restore.sh
current_location=\$(pwd)
ldap_admin_password=\$(kubectl get secret -n \$namespace openldap -o jsonpath="{.data.LDAP_ADMIN_PASSWORD}" | base64 --decode; echo)
ldap_pod=\$(kubectl get pods -n \$namespace | awk {'print \$1}' | grep -v NAME)
DIT=\$(kubectl exec -ti \$ldap_pod -n \$namespace -- /bin/bash -c "ldapsearch -x -b '' -s base '(&)' namingContexts -LLL | grep namingContexts: | sed 's/^.*: //'")

function exiting () {
        echo "Выход..."
        cd \$current_location
        }

function restore_with_delete() {
		if [ -f \$current_location/ldapsearch_ldap_backup_*.ldif ]
		then
		echo "File \$(ls -l \$current_location/ldapsearch_ldap_backup_*.ldif) exist"
		echo "Deleting current ldap database \$DIT"
		kubectl exec -ti $ldap_pod -n $namespace -- /bin/bash -c "ldapdelete -v -D "cn=admin,\$DIT" -w \$ldap_admin_password -r "\$DIT"" || { echo 'unable to delete ldap database' ; exit 1; }
		echo "Copying ldif file to pod"
		kubectl cp \$current_location/ldapsearch_ldap_backup_*.ldif \$namespace/\$ldap_pod:ldapsearch_ldap_backup.ldif
		echo "Restoring ldap database from ldif file"
		kubectl exec -ti $ldap_pod -n $namespace -- /bin/bash -c "ldapadd -x -D "cn=admin,\$DIT" -w \$ldap_admin_password -f ldapsearch_ldap_backup.ldif -v" || { echo 'unable to restore ldap database' ; exit 1; }
		else
		echo "There is no ldif restore file in the \$current_location"
		fi
}

function restore_without_delete() {
		if [ -f \$current_location/ldapsearch_ldap_backup_*.ldif ]
		then
		echo "File \$(ls -l \$current_location/ldapsearch_ldap_backup_*.ldif) exist"
		echo "Copying ldif file to pod"
		kubectl cp \$current_location/ldapsearch_ldap_backup_*.ldif \$namespace/\$ldap_pod:ldapsearch_ldap_backup.ldif
		echo "Restoring ldap database from ldif file"
		kubectl exec -ti $ldap_pod -n $namespace -- /bin/bash -c "ldapadd -x -D "cn=admin,\$DIT" -w \$ldap_admin_password -f ldapsearch_ldap_backup.ldif -v" || { echo 'unable to restore ldap database' ; exit 1; }
		else
		echo "There is no ldif restore file in the \$current_location"
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
