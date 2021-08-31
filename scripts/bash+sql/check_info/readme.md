Скрипт для проверки кол-ва сессий c выборкой по Machine и GROUP BY CLIENT_INFO, USERNAME

Установка:
1) git clone в /tmp/
2) меняем переменные в sh и sql скриптах

Установка графика выполнения:
```
# cronrab -e
# ### gather info regarding count of session from CLIENT_INFO
# 30 */1 * * * /tmp/check_CLIENT_INFO.sh &>/tmp/check_CLIENT_INFO.log
```
