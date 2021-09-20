#!/bin/bash

#\\\\\\\\\\\\\\\\\\\\\\#
#\\ STATIC VARIABLES \\#
#\\\\\\\\\\\\\\\\\\\\\\#

# цвета для красоты
green="\\033[0;32m"
yellow="\\033[0;33m"
red="\\033[0;31m"
color_off="\\033[0m"
cyan="\\033[0;36m"

# список версий бд
db_version_list='18.3\n18.10\n19.3'
db_install_log=tmp_db_install_$(date +"%d_%m_%Y__%H_%M").log
error="{ echo -e "${red}FAILED${color_off}" ; exit 1; }"

##################### webdav common ####################
webdav_username='eb_owncloud'
webdav_password='123'
webdav_url='https://oc.sigma-it.ru/owncloud/remote.php/dav/files/eb_admin/'

################# Oracle Database 18.3 #################
## webdav директория где хранится Oracle Database 18.3
oracle_18_3_webdav_dir='Oracle_18_3_and_upgrade_to_18_10/'
# Файлы и патчи для установки Oracle Database 18.3
oracle_18_3_db='V978967-01_DB_18_3.zip'

################# Oracle Database 18.10 #################
## webdav директория где хранится Oracle Database 18.10
oracle_18_10_webdav_dir='Oracle_18_3_and_upgrade_to_18_10/'
# Файлы и патчи для установки Oracle Database 18.10
oracle_18_10_db='V978967-01_DB_18_3.zip'
oracle_18_10_opatch='p6880880_122010_Linux-x86-64_Opatch_12.2.0.1.25.zip'
oracle_18_10_upgrade_from_18_3='p30899645_180000_Linux-x86-64_Patch_from_18_3_to_18_10.zip'

################# Oracle Database 19.3 #################
## webdav директория где хранится Oracle Database 19.3
oracle_19_3_webdav_dir='Oracle_19_3/'
# Файлы и патчи для установки Oracle Database 19.3
oracle_19_3_db='LINUX.X64_193000_db_home.zip'
oracle_19_3_patch='p29935685_193000DBRU_Linux-x86-64.zip'

#\\\\\\\\\\\\\\\\\\\\\\\#
#\\ DYNAMIC VARIABLES \\#
#\\\\\\\\\\\\\\\\\\\\\\\#
STAND_CODE=${1:-'ORCL'}
ORADATA=${2:-'/u01/oradata'}
DB_ROOT_DIR=${3:-'/u01'}
ORACLE_VERSION=${4:-'19.3'}
DB_PASSWORD=${5:-'welcome1'}

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#\\ Общие FUNCTIONS используемые в установках \\#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#

## function WebDav для загрузки файлов установки ##
function WebDav() {
echo -e "\n${cyan}######################################${color_off}"
echo -e "${green}Загрузка ${2} по WebDav в /tmp/${2}${color_off}\n"
echo -e "${yellow}curl -u "${webdav_username}:PASSWORD" ${webdav_url}${1}${2} --output /tmp/${2} --progress-bar | tee /dev/null${yellow}"
echo -e "${cyan}######################################${color_off}"
curl -u "${webdav_username}:${webdav_password}" ${webdav_url}${1}${2} --output /tmp/${2} --progress-bar | tee /dev/null
}

## function Выполнение root'вых скриптов во время установки БД через runInstaller и продолжение установки
function run_root_scripts() {
if grep -q "*execute the following script*" ${db_install_log}; then
    tail -12 ${db_install_log} | grep "^1." | awk '{print $2}' | eval
    sleep 8s
    tail -12 ${db_install_log} | grep "^2." | awk '{print $2}' | eval
    sleep 8s
    su - oracle -c ". ./${STAND_CODE}.env && $ORACLE_HOME/runInstaller -executeConfigTools -responseFile ${ORACLE_HOME}/install/response/db_istall_${STAND_CODE}.rsp -silent"
else
    echo -e "${red}Необходимо проверить лог установки БД на ошибки и перезапустить скрипт после устранения${color_off}\n"
    echo -e "${yellow}Возможные ошибки и их устаранение.\n
${red}Ошибка №1${color_off}\n
${yellow}--------------------------------------------------------------------
При установке БД через runInstaller(Silent mode) получаем ошибку:\n
WARNING:  [Aug 4, 2021 2:28:04 PM] [WARNING] [INS-32091] Software installation was successful. But some configuration assistants failed, were cancelled or skipped.
   ACTION: Refer to the logs or contact Oracle Support Services.
--------------------------------------------------------------------\n
Решение:
1. В данном случае hostname сервера с бд недоступен по короткому имени из за того что хост с бд не был внесён в dns. Что видно по ошибкам \"Unable to retrieve the full host name\" и \"Skipping line: [FATAL] [DBT-06103] The port (5,500) is already in use.\"
Проверяем лог установки на наличие след. записей:\n
----------------
INFO:  [Aug 4, 2021 2:27:53 PM] Gathering system details...
WARNING:  [Aug 4, 2021 2:27:53 PM] Unable to retrieve the full host name
INFO:  [Aug 4, 2021 2:27:53 PM] Registering setup bean
INFO:  [Aug 4, 2021 2:27:53 PM] Setting Response file data to the Installer
WARNING:  [Aug 4, 2021 2:27:53 PM] Unable to find the namespace URI. Reason: Start of root element expected.\n
INFO:  [Aug 4, 2021 2:28:04 PM] [FATAL] [DBT-06103] The port (5,500) is already in use.
INFO:  [Aug 4, 2021 2:28:04 PM] Skipping line: [FATAL] [DBT-06103] The port (5,500) is already in use.
INFO:  [Aug 4, 2021 2:28:04 PM]    ACTION: Specify a free port.
INFO:  [Aug 4, 2021 2:28:04 PM] Skipping line:    ACTION: Specify a free port.
INFO:  [Aug 4, 2021 2:28:04 PM] Completed Plugin named: Oracle Database Configuration Assistant\n
INFO:  [Aug 4, 2021 2:28:04 PM] Validating state <setup>
WARNING:  [Aug 4, 2021 2:28:04 PM] [WARNING] [INS-32091] Software installation was successful. But some configuration assistants failed, were cancelled or skipped.
   ACTION: Refer to the logs or contact Oracle Support Services.
----------------\n
2. Добавляем в /etc/hosts след. записи, проверяем что хост пингуется по не полному имени и перезапускаем установку.
vi /etc/hosts
172.16.100.20 dbtst-db.domain.ru dbtst-db
:wq!\n
[root@dbtst-db tmp]# ping dbtst-db
PING dbtst-db.domain.ru (172.16.100.20) 56(84) bytes of data.
64 bytes from dbtst-db.domain.ru (172.16.100.20): icmp_seq=1 ttl=64 time=0.040 ms
64 bytes from dbtst-db.domain.ru (172.16.100.20): icmp_seq=2 ttl=64 time=0.051 ms${color_off}"
fi
}

## function Проверка завершения runInstaller
function check_install() {
if grep -q "*Successfully Configured Software*" ${db_install_log}; then
    echo -e "${green}БД ${STAND_CODE} установлена!${color_off}"
else
    echo -e "${red}Необходимо проверить лог установки БД на ошибки и перезапустить скрипт после устранения${color_off}"
fi
}

## function Установка размера памяти бд в размере 90% от общей памяти сервера. в mb
function memory_size() {
    memory_sise=$(free -m | grep -i mem | awk '{print $2}')
    db_memory_size=$((${memory_sise}*90/100))
}

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#\\ FUNCTIONS Установки версий БД \\#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#

########################################################
### function 19_3_db_install with installation steps ###
########################################################
function 19_3_db_install() {
echo -e "${green}ШАГ 1. as root. Установка пакетов, создание директорий, oracle_preinstall${color_off}\n"
{
ORACLE_SID=${STAND_CODE}
ORACLE_HOME=${DB_ROOT_DIR}/app/oracle/product/19.3.0.0
TNS_ADMIN=$ORACLE_HOME/network/admin
PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch
ORACLE_BASE=${DB_ROOT_DIR}/app/oracle
ORADATA=${ORADATA}
ORADBCFG=${DB_ROOT_DIR}/dbconfig
ORAAUDIT=${DB_ROOT_DIR}/audit
ORADIAG=${DB_ROOT_DIR}

  yum install -y wget \
                     telnet \
                     net-tools \
                     iproute \
                     iputils \
                     unzip \
                     vim \
                     git && \
      mkdir -p $ORACLE_HOME $ORADATA $ORADBCFG $ORAAUDIT   && \
      chown -R oracle:oinstall ${DB_ROOT_DIR} && \
      chown -R oracle:oinstall $ORADATA && \
      yum update -y && \
      yum clean all && \
      rm -rf /var/tmp/*
  cd /tmp/ && yum install -y oracle-database-preinstall-19c
} || { echo 'FAILED' ; exit 1; }

echo -e "${green}ШАГ 2. as oracle. Создание ${STAND_CODE}.env файла${color_off}\n"
su - oracle -c "echo -n \"export ORACLE_SID=${STAND_CODE}
export ORACLE_HOME=${DB_ROOT_DIR}/app/oracle/product/19.3.0.0
export TNS_ADMIN=\$ORACLE_HOME/network/admin
export PATH=\$PATH:\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch
export ORACLE_BASE=${DB_ROOT_DIR}/app/oracle
export ORADATA=${ORADATA}
export ORADBCFG=${DB_ROOT_DIR}/dbconfig
export ORAAUDIT=${DB_ROOT_DIR}/audit
export ORADIAG=${DB_ROOT_DIR}\" > ${STAND_CODE}.env" && echo -e "${yellow}${STAND_CODE}.env cоздан${color_off}\n" || ${error}

echo -e "${green}ШАГ 3. as oracle. Распаковка bin'арников${color_off}\n"
su - oracle -c ". ./${STAND_CODE}.env && cd $ORACLE_BASE/product/19.3.0.0 && cp /tmp/LINUX.X64_193000_db_home.zip ./ && unzip LINUX.X64_193000_db_home.zip && rm -f LINUX.X64_193000_db_home.zip" || { echo 'FAILED' ; exit 1; }

echo -e "${green}ШАГ 4. as oracle. Создание response file для \"Тихой\" установки${color_off}\n"
su - oracle -c ". ./${STAND_CODE}.env && echo -n \"oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
oracle.install.option=INSTALL_DB_AND_CONFIG
UNIX_GROUP_NAME=oinstall
INVENTORY_LOCATION=${DB_ROOT_DIR}/app/oraInventory
ORACLE_BASE=${ORACLE_BASE}
oracle.install.db.InstallEdition=EE
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=oper
oracle.install.db.OSBACKUPDBA_GROUP=backupdba
oracle.install.db.OSDGDBA_GROUP=dgdba
oracle.install.db.OSKMDBA_GROUP=kmdba
oracle.install.db.OSRACDBA_GROUP=racdba
oracle.install.db.CLUSTER_NODES=
oracle.install.db.config.starterdb.type=GENERAL_PURPOSE
oracle.install.db.config.starterdb.globalDBName=DBTST
oracle.install.db.config.starterdb.SID=DBTST
oracle.install.db.ConfigureAsContainerDB=false
oracle.install.db.config.PDBName=
oracle.install.db.config.starterdb.characterSet=CL8ISO8859P5
oracle.install.db.config.starterdb.memoryOption=false
oracle.install.db.config.starterdb.memoryLimit=226539
oracle.install.db.config.starterdb.installExampleSchemas=false
oracle.install.db.config.starterdb.password.ALL=
oracle.install.db.config.starterdb.password.SYS=welcome1
oracle.install.db.config.starterdb.password.SYSTEM=welcome1
oracle.install.db.config.starterdb.password.DBSNMP=
oracle.install.db.config.starterdb.password.PDBADMIN=
oracle.install.db.config.starterdb.managementOption=DEFAULT
oracle.install.db.config.starterdb.omsHost=
oracle.install.db.config.starterdb.omsPort=0
oracle.install.db.config.starterdb.emAdminUser=
oracle.install.db.config.starterdb.emAdminPassword=
oracle.install.db.config.starterdb.enableRecovery=false
oracle.install.db.config.starterdb.storageType=FILE_SYSTEM_STORAGE
oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=/sgm/data
oracle.install.db.config.starterdb.fileSystemStorage.recoveryLocation=
oracle.install.db.config.asm.diskGroup=
oracle.install.db.config.asm.ASMSNMPPassword=\" > ${ORACLE_HOME}/install/response/db_istall_${STAND_CODE}.rsp" || ${error}

echo -e "${green}ШАГ 5. as oracle. Установка OracleSoftware and db через response file (silent mode)${color_off}\n"
su - oracle -c ". ./${STAND_CODE}.env &&
$ORACLE_HOME/runInstaller -ignorePrereq -waitforcompletion -silent             	  	\
    -responseFile ${ORACLE_HOME}/install/response/db_istall_${STAND_CODE}.rsp 	  	\
    ORACLE_HOSTNAME=${ORACLE_HOSTNAME}                                         	  	\
    ORACLE_HOME=${ORACLE_HOME}                                                 	  	\
    ORACLE_BASE=${ORACLE_BASE}            											                    \
    oracle.install.db.config.starterdb.characterSet=CL8ISO8859P5        			      \
    INVENTORY_LOCATION=${DB_ROOT_DIR}/app/oraInventory                              \
    oracle.install.db.config.starterdb.globalDBName=${ORACLE_SID}                   \
    oracle.install.db.config.starterdb.SID=${ORACLE_SID}                            \
    oracle.install.db.config.starterdb.memoryLimit=${db_memory_size}                \
    oracle.install.db.config.starterdb.password.SYS=${DB_PASSWORD}                  \
    oracle.install.db.config.starterdb.password.SYSTEM=${DB_PASSWORD}               \
    oracle.install.db.config.starterdb.fileSystemStorage.dataLocation=${ORADATA}"

echo -e "${green}ШАГ 6. as root then as oracle. Выполнение root'вых скриптов и продолжение установки ${color_off}\n"
run_root_scripts || ${error}

echo -e "${green}ШАГ 7. Проверка установки БД${color_off}\n"
check_install || ${error}
}


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#\\\ УСТАНОВКА БД СОГЛАСНО СОГЛАСНО ЗАПРОШЕННОЙ ВЕРСИИ. 19.3 СТАВИТСЯ ПО ДЕФОЛТУ \\\#
#\\ Выбирается согласно логике "if версия elif версия elif версия elif версия fi" \\#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
echo -e "${cyan}######################################${color_off}"
echo -e "${cyan}Установка Oracle Database ${ORACLE_VERSION}\nИмя базы: ${STAND_CODE}\nРасположение датафайлов: ${ORADATA}\nДиректория установки: ${DB_ROOT_DIR}${color_off}"
echo -e "${cyan}######################################${color_off}\n"

##########################################
########## Oracle Database 19.3 ##########
##########################################
if [ "${ORACLE_VERSION}" == '19.3' ]
then
echo -e "${green}Установка переменных \$oracle_version \$webdav_dir согласно входному аргументу ORACLE_VERSION=${ORACLE_VERSION}${color_off}\n"
ORACLE_VERSION='oracle_19_3'
webdav_dir=${oracle_19_3_webdav_dir}
echo -e "${green}Загрузка файлов для установки с webdav сервера${color_off}\n"
compgen -v | grep -i ${ORACLE_VERSION} | grep -v dir | while read variables; do WebDav ${webdav_dir} ${!variables}; done
echo -e "${green}Вызов функции установки версии ${ORACLE_VERSION}${color_off}\n"
memory_size && 19_3_db_install | tee /tmp/${db_install_log} 2>&1
##########################################
########## Oracle Database 18.10 #########
##########################################
elif [ "${ORACLE_VERSION}" == '18.10' ]
then
echo -e "${green}Установка переменных \$oracle_version \$webdav_dir согласно входному аргументу ORACLE_VERSION=${ORACLE_VERSION}${color_off}\n"
ORACLE_VERSION='oracle_18_10'
webdav_dir=${oracle_18_10_webdav_dir}
echo -e "${green}Загрузка файлов для установки с webdav сервера${color_off}\n"
compgen -v | grep -i ${ORACLE_VERSION} | grep -v dir | while read variables; do WebDav ${webdav_dir} ${!variables}; done
echo -e "${green}Вызов функции установки версии ${ORACLE_VERSION}${color_off}\n"
memory_size && 18_10_db_install | tee /tmp/${db_install_log} 2>&1
#########################################
########## Oracle Database 18.3 #########
#########################################
elif [ "${ORACLE_VERSION}" == '18.3' ]
then
echo -e "${green}Установка переменных \$oracle_version \$webdav_dir согласно входному аргументу ORACLE_VERSION=${ORACLE_VERSION}${color_off}\n"
ORACLE_VERSION='oracle_18_3'
webdav_dir=${oracle_18_3_webdav_dir}
echo -e "${green}Загрузка файлов для установки с webdav сервера${color_off}\n"
compgen -v | grep -i ${ORACLE_VERSION} | grep -v dir | while read variables; do WebDav ${webdav_dir} ${!variables}; done
echo -e "${green}Вызов функции установки версии ${ORACLE_VERSION}${color_off}\n"
memory_size && 18_3_db_install | tee /tmp/${db_install_log} 2>&1
#########################################
else
echo -e "${red}Некорректно указана версия Oracle Database - ${ORACLE_VERSION}. Необходимо выбрать одну из следующих версий:{color_off}"
echo -e "${red}${version_list}${color_off}"
fi
