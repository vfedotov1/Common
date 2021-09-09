# Common
git clone https://github.com/vfedotov1/Common.git
# ansible
git clone https://github.com/vfedotov1/Common.git && mv Common/ansible ./ && rm -rf Common/
#
echo -e "export ANSIBLE_CONFIG=~/ansible/ansible.cfg
export ANSIBLE_PLAYBOOK_DIR=~/ansible/playbooks
# export ANSIBLE_LIBRARY=/srv/modules/custom_modules:/srv/modules/vendor_modules
echo \"##############################################################################\"
test \"x\${ANSIBLE_CONFIG}\" = \"x\" || echo \"## ANSIBLE_CONFIG=\${ANSIBLE_CONFIG}\"
test \"x\${ANSIBLE_PLAYBOOK_DIR}\" = \"x\" || echo \"## ANSIBLE_PLAYBOOK_DIR=\${ANSIBLE_PLAYBOOK_DIR}\"
echo \"##\"
cat \$ANSIBLE_CONFIG | while read LINE; do echo \"## \$LINE\"; done
echo \"##############################################################################\"" >> .bash_profile
# vagrant
git clone https://github.com/vfedotov1/Common.git && mv Common/vagrant ./ && rm -rf Common/ && chmod +x vagrant/*sh
# scripts
git clone https://github.com/vfedotov1/Common.git && mv Common/vagrant ./ && rm -rf Common/
