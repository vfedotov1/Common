# INPUT VARIABLES
dns_server_adress=$1 # EXAMPLE 192.168.0.20
allow_query_subnet=$2 # EXAMPLE 192.168.0.0/24
forwarders_gateway=$3 # EXAMPLE 192.168.0.1
zone_name=$4 # EXAMPLE home.local.ru
reverse_name_zone=$(echo $dns_server_adress | awk -F\. '{print $3"."$2"."$1}') # EXAMPLE 0.168.192
reverse_zone_last_actet=$(echo $dns_server_adress | awk -F\. '{print $4}') # EXAMPLE 20

# 1) Install packages
yum -y install bind

# 2) Enable autostart
systemctl enable named

# 3) Start and check status
systemctl start named
systemctl status named

# 4) Настраиваем conf файл bind
tee /etc/named.conf << EOF
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html

acl "trusted" {
        $dns_server_adress;
};
options {
        listen-on port 53 { 127.0.0.1; $dns_server_adress; };
        listen-on-v6 port 53 { none; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query     { localhost; $allow_query_subnet; };
        forward first;
        forwarders {$forwarders_gateway;};
        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
         - If you are building a RECURSIVE (caching) DNS server, you need to enable
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        recursion yes;

        dnssec-enable yes;
        dnssec-validation yes;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.root.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "$zone_name" {
        type master;
        file "master/$zone_name";
};

zone "$reverse_name_zone.in-addr.arpa" {
    type master;
    file "master/$reverse_name_zone.zone";
};

zone "." IN {
        type hint;
        file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF
#
# 4.1)
# acl 192.168.0.21; - Cекция позволяющая создать access control list из IP-адресов, дабы потом не перечеслять их каждый раз в других секциях. acl «trusted-dns» в данном случае описывает IP-адреса доверительных DNS серверов которым позволено скачивать зоны полностью с нашего DNS сервера, т.к. по умолчанию скачать копию вашей зоны с вашего master DNS сервера сможет любой желающий указав с своем конфиге IP-адрес вашего master DNS сервера как первичного для вашей зоны. Если вы собираетесь вводить ограничения не скачивание файла зоны, то не забудьте в acl указать IP-адрес(а) вторичного(ных) DNS сервера(ов).
# listen-on port 53 { 127.0.0.1; 192.168.0.20; }; - Адрес DNS сервера
# allow-query     { localhost; 192.168.0.0/24; };  - Разрешает выполнять запрос из конкретной подсети (указываем свою)
# listen-on-v6 port 53 { none; }; - Отключаем IPV6
# forward first; - (first; действует только при непустом списке forwarders; перенаправлять запросы, не имеющие ответов в кеше или своих зонах, серверам, указанным в списке forwarders; позволяет организовать общий кеш для нескольких серверов или доступ в Интернет через прокси; first - сначала делается запрос к серверам из списка, при неудаче производится собственный поиск;)
# forwarders {192.168.0.1;}; - Перенаправляем запросы, которые не резолвятся на днс сервер роутера (наш шлюз).
#
# 4.2)
# В /etc/named.conf добавляем запись о прямой DNS зоне home.local.ru созданную в п.6 (Для каждой зоны добавляется свой блок zone в файл named.conf)
# zone - собственно секция отвечающая за поддержку нашего тестового домена home.local.ru данный сервер является мастером (master) для данной зоны. Внутри секции zone идет «ссылка» на «trusted-dns» - acl смысл которого описан в п.4. Секция zone обязательно должна описывать: тип (type) зоны (master или slave), путь до файла (file) зоны. В случае если это тип slave добавляется обязательный параметр masters:
# masters { IP-ADDRESS; };
# где IP-ADDRESS это адрес первичного DNS сервера для данной зоны.
#
# zone "home.local.ru" {
#         type master;
#         file "master/home.local.ru";
# };
#
# type  - тип зоны (в нашем случае первичная - значит master). Другие варианты - slave, stub, forward.
# file - Путь к файлу с записями зоны. В данном примере указан относительный путь - то есть файл находится по пути master/home.local.ru , который начинается относительно рабочей директории (по умолчанию - /var/named/). Таким образом, полный путь до файла - /var/named/master/home.local.ru
#
# 4.3)
# В /etc/named.conf добавляем запись об обратной DNS зоне
#
# vi /etc/named.conf
# zone "0.168.192.in-addr.arpa" {
#     type master;
#     file "master/0.168.192.zone";
# };
#

# 5) Создаем директорию с мастер зонами
mkdir -p /var/named/master/

# 6) Создание прямой DNS зоны
tee /var/named/master/$zone_name << EOF
\$TTL 3600         ;
$zone_name.    IN      SOA     $(hostname).$zone_name. root.$zone_name. (
                  1               ; Serial
                  600             ; Refresh
                  3600            ; Retry
                  1w              ; Expire
                  360             ; Minimum TTL
                  )
          IN      NS      $(hostname).$zone_name.
          IN      A       $dns_server_adress
$(hostname)       IN      A       $dns_server_adress
db2       IN      A       192.168.0.21
EOF
# $TTL 3600 - Time to live время жизни, по умолчанию 1 день. По достижении установленного времени, кеширующий сервер запрашивает DNS сервер, содержащий доменную зону, информацию о зоне. И при необходимости обновляет записи.
# home.local.ru. IN SOA db1.home.local.ru. root.home.local.ru. - Зона обслуживания, адрес корневого сервера для зоны, аккаунт её админа.
# 1; Serial - Её серийный номер DNS записи.
# 600; Refresh - Указывает подчиненным DNS серверам как часто им обращаться, для поиска изменений к master серверу.
# 3600; Retry - Говорит о том, сколько Slave сервер должен подождать, прежде чем повторить попытку.
# 1w; Expire - Максимальный срок жизни записей, после которой они потеряют актуальность (1 неделя)
# 300; Minimum TTL - Минимальный срок жизни записи 5 мин.
# IN NS db1.home.local.ru. - NS сервер который обслуживает эту зону
# IN A 192.168.0.20 - Если требуется попасть по адресу home.local.ru , то клиенту будет выдан этот IP
# db1 IN A 192.168.0.20 - Адрес нашего NS сервера
# db2 IN A 192.168.0.21 - Если клиент запрашивает адрес db2.home.local.ru , DNS выдаст ip 192.168.0.21

# 7) Назначение владельца и права.
chown -R root:named /var/named/master
chmod 0640 /var/named/master/*

# 8) Создание обратной DNS зоны
tee /var/named/master/$reverse_name_zone.zone << EOF
\$TTL 3600         ;
@         IN      SOA     $(hostname).$zone_name. root.$zone_name. (
                  1               ; Serial
                  600             ; Refresh
                  3600            ; Retry
                  1w              ; Expire
                  360             ; Minimum TTL
                  )
@         IN      NS      $(hostname).$zone_name.
$reverse_zone_last_actet        IN      PTR     $(hostname).$zone_name.
21        IN      PTR     db2.$zone_name.
EOF

# 9) Перезапускаем службу для применения настроек
systemctl restart named

# 10) Проверяем работу прямой DNS зоны с помощью nslookup’a сайта yandex.ru (Можно через windows). При необходимости может потребоваться открыть 53 udp port на DNS сервере.
nslookup yandex.ru $dns_server_adress

# 11) Проверяем работу обратной DNS зоны с помощью nslookup’a ip нашего же DNS сервера (Можно через windows). При необходимости может потребоваться открыть 53 udp port на DNS сервере.
nslookup $dns_server_adress $dns_server_adress

# 12) Добавляем в /etc/resolv.conf запись о DNS сервере.
tee /etc/resolv.conf << EOF
# Generated by NetworkManager
nameserver $dns_server_adress
nameserver $forwarders_gateway
nameserver 8.8.8.8
search $zone_name
EOF
# nameserver  - Директива «nameserver» указывает на IP адрес DNS сервера. Замечание: Можно указать максимум 3 DNS сервера. Желательно указывать первым самый стабильный.
# nameserver 192.168.0.20 - Адрес нашего DNS сервера.
# nameserver 192.168.0.1 - К примеру если необходим доступ в интернет, в случае недоступности нашего DNS сервера, то можно указать адрес роутера/шлюза (Он используется как forwarders в нашем созданном DNS. см. запись выше)
# nameserver 8.8.8.8 - Так же можно указывать DNS адреса google, но лучше указывать в последнюю очередь, т.к. имеется лимит на запросы, что влияет на производительность спустя n-ое кол-во запросов.
# search home.local.ru - Директива «search» для преобразования коротких доменных имен. (К примеру db1 в db1.home.local.ru).
# Можно поместить несколько доменных имен «search home.local.ru NOhome.local.ru». Тогда, Ваш компьютер будет пытаться преобразовать db1, как доменное имя db1.home.local.ru , а затем как db1.NOhome.local.ru. В качестве IP адреса будет возвращено первое успешное преобразование.
# Замечание: Данная директива похожа с директивой «domain». Необходимо использовать либо domain, либо search. Лучше использовать search. Если указать оба, то поиск будет использоваться по последней в списке опции.
