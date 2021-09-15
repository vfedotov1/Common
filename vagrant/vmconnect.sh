# mvconnect.sh script for mobaxterm # Works exactly the way `vagrant ssh` should
# run as ./vmconnect.sh ubuntu
vm_name=${1:-'ansible'} # vm name
if [ -f "./vagrant-ssh_${vm_name}" ]
then
echo "vagrant-ssh already created"
ssh -F vagrant-ssh_${vm_name} ${vm_name}
else
echo "creating vagrant-ssh"
vagrant ssh-config ${vm_name} > ./vagrant-ssh_${vm_name}
ssh -F vagrant-ssh_${vm_name} ${vm_name}
fi
