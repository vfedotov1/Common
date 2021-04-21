#!/bin/bash

# Поиск по абоненту в Service логах /bu01/logs
# Скрипт осуществляет поиск абонента по всех логам за указанное число и создает файл /tmp/NSD${abonent}/${abonent}.log c выборкой по абоненту
# Так же в директории /tmp/NSD${abonent}/ будет создан файл list_of_files_where_mentioned${abonent} где в случае необходимости можно будет найти список логов где упоминается абонент

# HOW TO RUN
# ./abonent.sh
# Будут запрошены след. параметры:
#                                 - Номер заявки
#                                 - Дата лога в формате YYYY-MM-DD
#                                 - Вторая часть номера абонента 002\00396583 <----- "00396583"

echo -e "Поиск по абоненту в Service логах \n\nВведите номер заявки (Пример:NSD123456): "
read NSD
echo -e "\nВведите дату лога в формате YYYY-MM-DD (Пример:2019-10-22): "
read date_of_log
echo -e "\nВведите вторую часть номера абонента (Пример:01000289): "
read abonent

# создание директории для лога скрипта
if [ -d ~/abonent/sh_log ]
  then
  echo "Directory exist"
  else
    mkdir ~/abonent/sh_log
    fi

#Переменные используются ток в функции find_log
path_to_created_log="/tmp/${NSD}/${abonent}.log"
list_of_files_where_mentioned_abonent="/tmp/$NSD/list_of_files_where_mentioned${abonent}"
echo -e "\n\n###############################################################################"
echo -e "По заявке $NSD будет произведен поиск абонента $abonent за дату $date_of_log"
echo -e "###############################################################################"

function error() {
        echo -e "\nАбонент не найден"
        cd ~/abonent/
}

function find_log() {
        echo -e "\nПоиск абонента..."
        mkdir -p /tmp/${NSD}
        find /bu01/log{s,s2}/app0{1,2}.Service**${date_of_log}* -type f -name "app0*.Service**${date_of_log}*" -exec zgrep -l "${abonent}" {} \; >/tmp/$NSD/list_of_files_where_mentioned${abonent}
        cat /tmp/${NSD}/list_of_files_where_mentioned${abonent} | while read LINE; do zgrep -C 40 ${abonent} $LINE >> /tmp/$NSD/${abonent}.log; done
        if
        [ -f "/tmp/${NSD}/${abonent}.log" ]
        then
                #list_of_files_where_mentioned_abonent
        #echo -e "Список логов где упоминается абонент ${list_of_files_where_mentioned_abonent}"
        echo -e "\nВыборка по абоненту за ${date_of_log} расположена в ${path_to_created_log}\nНе забудь выполить:\nrm -rf /tmp/${NSD}\n"
        exiting
        else
        error
        fi
}

function exiting () {
        echo "Выход..."
        cd ~/abonent/
        }

        function choise1() {
        echo -e "\n\nВыберите один из след. вариантов: \n1. Продолжить поиск абонента; \n2. Выход; \n\nYour choise is?"
        read choise
        case $choise in
        1)
                find_log;;
        2)
                exiting;;
        esac
        }

        {
        choise1
        } | tee -a ~/abonent/sh_log/abonent_sh_${NSD}.log
