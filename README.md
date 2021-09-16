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

##################################################################################
### vagrant + vagrant destroy all vm + vagrant up all vm  + connect to ansible ###
##################################################################################
{
VBoxManage="/drives/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe"
# function kill all vm via virtualbox
function killvms() {
    eval ${VBoxManage} list runningvms | awk '{print $2;}' | while read vmid; do eval ${VBoxManage} controlvm ${vmid} poweroff; done
    eval ${VBoxManage} list vms | awk '{print $2;}' | while read vmid; do eval ${VBoxManage} unregistervm --delete ${vmid}; done
  }
# kill all vm via vagrantdestroy otherwise
vagrant global-status | grep virtualbox | awk '{print $1}' | xargs vagrant destroy -f || killvms
cd ../ && rm -rf vagrant/ Common/ && git clone https://github.com/vfedotov1/Common.git && mv Common/vagrant ./ && rm -rf Common/ && chmod +x vagrant/*sh && cd vagrant && vagrant up && ./vmconnect.sh
}

###############
### scripts ###
###############
git clone https://github.com/vfedotov1/Common.git && mv Common/scripts ./ && rm -rf Common/

###########
### dns ###
###########
git clone https://github.com/vfedotov1/Common.git && mv Common/scripts/bash/create_dns_server_auto.sh ./ && rm -rf Common/
