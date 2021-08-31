Репорт отправляется письмом с темой "ПРОЕКТ. Daily log's growth Report" каждый день через cron user@server на "Администраторы БД <user_1@mail.ru>; Дежурные администраторы БД <user_2@mail.ru>"

В репорт входит:
  - информация по размеру логов сервисов ЕБ за предыдущий день
  - информация по приросту размеров таблиц содержащих логи (инфа берется с sys.table_growth_job) за предыдущий день

Мониторинг роста таблиц производится джобой sys.table_growth_job в бд DB_NAME (Выполняется каждый день в 23:45)

Джобой выполняется следующее:
  - в таблицу system.table_growth добавляется информация по размеру таблиц указанных в джобе
  - высчитывается прирост в mb относительно прошлого дня

Историю по размерам и приросту в день можно посмотреть в sys.table_growth_job.

Установка:
1) выполнить git clone в /home/fusion/
2) для функционирования в /home/fusion/logs_size_sh/ обязательно должны быть след. файлы:
list_of_directories_gz
list_of_directories_file
txt_to_html.sh
size_of_services_log.sh
3) В скрипте create_job_TABLE_GROWTH_JOB.sql необходимо поменять выборку на нужные таблицы и схемы для джобы CREATE_JOB
4) Прогнать скрипты prepare_scripts в бд из под sys или system
5) Положить на сервер бд в /home/oracle скрипт table_growth.sql
6) Прописать в list_of_directories* пути до директорий с файлами логов
7) Указать корректный хост бд в скрипте size_of_services_log.sh
8) Указать в функции send_mail корректное имя сервера
9) Указать в корректные email'ы отправки в скрипте size_of_services_log.sh
10) Заменить "ПРОЕКТ" на название стенда в size_of_services_log.sh и название бд при отправке email'а
11) В size_of_services_log.sh используется HARDCODE при сложении идентичных логов + мб где-то еще.

Установка графика выполнения:
```
crontab -e
### ПРОЕКТ. Daily log's growth Report
0 9 * * * /home/fusion/logs_size_sh/size_of_services_log.sh 1>/tmp/size_of_services_log.sh.log 2>&1
```

Что доработать:
- Вынести все переменные в начало скрипта
- Копировать скрипт table_growth.sql каждый раз на сервер, если его нет
- По возможности убрать HARDCODE
