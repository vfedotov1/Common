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

#\\\\\\\\\\\\\\\#
#\\ FUNCTIONS \\#
#\\\\\\\\\\\\\\\#

## function WebDav для загрузки файлов установки ##
function WebDav() {
echo -e "\n${cyan}######################################${color_off}"
echo -e "${green}Загрузка ${2} по WebDav в /tmp/${2}${color_off}\n"
echo -e "${yellow}curl -u "${webdav_username}:PASSWORD" ${webdav_url}${1}${2} --output /tmp/${2} --progress-bar | tee /dev/null${yellow}"
echo -e "${cyan}######################################${color_off}"
curl -u "${webdav_username}:${webdav_password}" ${webdav_url}${1}${2} --output /tmp/${2} --progress-bar | tee /dev/null
}

########################################################
### function 19_3_db_install with installation steps ###
########################################################
function 19_3_db_install() {
# 1. as root. Установка пакетов, создание директорий, oracle_preinstall
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
# 2. as oracle. create env files
su - oracle -c 'echo -n "export ORACLE_SID=${STAND_CODE}
export ORACLE_HOME=${DB_ROOT_DIR}/app/oracle/product/19.3.0.0
export TNS_ADMIN=\$ORACLE_HOME/network/admin
export PATH=\$PATH:\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch
export ORACLE_BASE=${DB_ROOT_DIR}/app/oracle
export ORADATA=${ORADATA}
export ORADBCFG=${DB_ROOT_DIR}/dbconfig
export ORAAUDIT=${DB_ROOT_DIR}/audit
export ORADIAG=${DB_ROOT_DIR}" > DBTST.env'
}


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#\\\ УСТАНОВКА БД СОГЛАСНО СОГЛАСНО ЗАПРОШЕННОЙ ВЕРСИИ. 19.3 СТАВИТСЯ ПО ДЕФОЛТУ \\\#
#\\ Выбирается согласно логике "if версия elif версия elif версия elif версия fi" \\#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
echo -e "${cyan}######################################${color_off}"
echo -e "${cyan}Установка Oracle Database ${ORACLE_VERSION}\nИмя базы: ${STAND_CODE}\nРасположение датафайлов: ${ORADATA}\nДиректория установки= ${DB_ROOT_DIR}${color_off}"
echo -e "${cyan}######################################${color_off}\n"

##########################################
########## Oracle Database 19.3 ##########
##########################################
if [ "${ORACLE_VERSION}" == '19.3' ]
then
echo -e "${green}Установка переменных \$oracle_version \$webdav_dir согласно входному аргументу ORACLE_VERSION=${ORACLE_VERSION}${color_off}"
ORACLE_VERSION='oracle_19_3'
webdav_dir=${oracle_19_3_webdav_dir}
echo -e "${green}Загрузка файлов для установки с webdav сервера${color_off}"
compgen -v | grep -i ${ORACLE_VERSION} | grep -v dir | while read variables; do WebDav ${webdav_dir} ${!variables}; done
echo -e "${green}Вызов функции установки версии ${ORACLE_VERSION}${color_off}"
19_3_db_install
##########################################
########## Oracle Database 18.10 #########
##########################################
elif [ "${ORACLE_VERSION}" == '18.10' ]
then
echo -e "${green}Установка переменных \$oracle_version \$webdav_dir согласно входному аргументу ORACLE_VERSION=${ORACLE_VERSION}${color_off}"
ORACLE_VERSION='oracle_18_10'
webdav_dir=${oracle_18_10_webdav_dir}
echo -e "${green}Загрузка файлов для установки с webdav сервера${color_off}"
compgen -v | grep -i ${ORACLE_VERSION} | grep -v dir | while read variables; do WebDav ${webdav_dir} ${!variables}; done
echo -e "${green}Вызов функции установки версии ${ORACLE_VERSION}${color_off}"
18_10_db_install
#########################################
########## Oracle Database 18.3 #########
##########################################
elif [ "${ORACLE_VERSION}" == '18.3' ]
then
echo -e "${green}Установка переменных \$oracle_version \$webdav_dir согласно входному аргументу ORACLE_VERSION=${ORACLE_VERSION}${color_off}"
ORACLE_VERSION='oracle_18_3'
webdav_dir=${oracle_18_3_webdav_dir}
echo -e "${green}Загрузка файлов для установки с webdav сервера${color_off}"
compgen -v | grep -i ${ORACLE_VERSION} | grep -v dir | while read variables; do WebDav ${webdav_dir} ${!variables}; done
echo -e "${green}Вызов функции установки версии ${ORACLE_VERSION}${color_off}"
18_3_db_install
else
echo "${red}Некорректно указана версия Oracle Database - ${ORACLE_VERSION}. Необходимо выбрать одну из следующих версий:{color_off}"
echo -e  ${red}${version_list}${color_off}
fi
