# Common
git clone https://github.com/vfedotov1/Common.git

# ansible
git clone https://github.com/vfedotov1/Common.git && mv Common/ansible ./ && rm -rf Common/

# vagrant + vagrant up ansible
git clone https://github.com/vfedotov1/Common.git && mv Common/vagrant ./ && rm -rf Common/ && chmod +x vagrant/*sh && cd vagrant && vagrant up && ./vmconnect.sh

# vagrant + vagrant destroy all vm + vagrant up all vm
{
vagrant global-status | grep virtualbox | awk '{print $1}' | xargs vagrant destroy -f
git clone https://github.com/vfedotov1/Common.git && mv Common/vagrant ./ && rm -rf Common/ && chmod +x vagrant/*sh && cd vagrant && vagrant up ansible ol7 && ./vmconnect.sh
}

# scripts
git clone https://github.com/vfedotov1/Common.git && mv Common/scripts ./ && rm -rf Common/

# dns
git clone https://github.com/vfedotov1/Common.git && mv Common/scripts/bash/create_dns_server_auto.sh ./ && rm -rf Common/
