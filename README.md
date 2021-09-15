# Common
git clone https://github.com/vfedotov1/Common.git

# ansible
git clone https://github.com/vfedotov1/Common.git && mv Common/ansible ./ && rm -rf Common/

# vagrant + vagrant up ansible
git clone https://github.com/vfedotov1/Common.git && mv Common/vagrant ./ && rm -rf Common/ && chmod +x vagrant/*sh && cd vagrant && vagrant up && ./vmconnect.sh

# scripts
git clone https://github.com/vfedotov1/Common.git && mv Common/scripts ./ && rm -rf Common/

# dns
git clone https://github.com/vfedotov1/Common.git && mv Common/scripts/bash/create_dns_server_auto.sh ./ && rm -rf Common/
