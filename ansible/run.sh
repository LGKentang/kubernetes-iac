ANSIBLE_HOST_KEY_CHECKING=False ansible -i inventory/hosts.yaml all -m ping
ansible-playbook playbooks/01-common.yaml
ansible-playbook playbooks/02-master.yaml
ansible-playbook playbooks/03-master-join.yaml
ansible-playbook playbooks/04-worker.yaml
