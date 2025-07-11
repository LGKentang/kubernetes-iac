ANSIBLE_HOST_KEY_CHECKING=False ansible -i inventory/hosts.yaml all -m ping --ask-pass
ansible-playbook playbooks/01-common.yaml --ask-pass
ansible-playbook playbooks/02-master.yaml --ask-pass
ansible-playbook playbooks/03-worker.yaml --ask-pass
