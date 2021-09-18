Загрузка репозитория:

##############
### Common ###
##############
git clone https://github.com/vfedotov1/Common.git

###############
### ansible ###
###############
git clone https://github.com/vfedotov1/Common.git && mv Common/ansible ./ && rm -rf Common/

#########################################################
### vagrant + vagrant up ansible + connect to ansible ###
#########################################################
git clone https://github.com/vfedotov1/Common.git && mv Common/vagrant ./ && rm -rf Common/ && chmod +x vagrant/*sh && cd vagrant && vagrant up ansible && ./vmconnect.sh

######################################################################################
### vagrant + kill all vm via VBoxManage + vagrant up all vm  + connect to ansible ###
######################################################################################
{
VBoxManage="/drives/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe"
# function kill all vagrant vm via virtualbox
function killvms() {
    eval ${VBoxManage} list runningvms | grep vagrant | awk '{print $2;}' | while read vmid; do eval ${VBoxManage} controlvm ${vmid} poweroff; done
    eval ${VBoxManage} list vms | grep vagrant | awk '{print $2;}' | while read vmid; do eval ${VBoxManage} unregistervm --delete ${vmid}; done
  }
# kill all vm via vagrantdestroy otherwise
killvms
#vagrant global-status | grep virtualbox | awk '{print $1}' | xargs vagrant destroy -f || killvms
rm -rf vagrant/ Common/ && git clone https://github.com/vfedotov1/Common.git && mv Common/vagrant ./ && rm -rf Common/ && chmod +x vagrant/*sh && cd vagrant && vagrant up && ./vmconnect.sh
}

###############
### scripts ###
###############
git clone https://github.com/vfedotov1/Common.git && mv Common/scripts ./ && rm -rf Common/ && find scripts/ -type f -name "*.sh" | xargs chmod +x

###########
### dns ### Common\scripts\bash\create_dns_server_auto.sh
###########
git clone https://github.com/vfedotov1/Common.git && mv Common/scripts/bash/create_dns_server_auto.sh ./ && rm -rf Common/ && chmod + x create_dns_server_auto.sh
