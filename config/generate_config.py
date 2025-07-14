import yaml
from pathlib import Path

GATEWAY = "192.168.1.1"
DNS = "8.8.8.8"

with open("node-config.yaml") as f:
    config = yaml.safe_load(f)

terraform_masters = {}
terraform_workers = {}

ansible_inventory = {
    "all": {
        "children": {
            "masters": {"hosts": {}},
            "workers": {"hosts": {}}
        }
    }
}

def make_hostname(name, role):
    return f"KUBE-{role[:-1].upper()}-TERRAFORM-{name.split('-')[-1]}"

for master in config.get("masters", []):
    name, ip = master["name"], master["ip"]

    terraform_masters[name] = {
        "hostname": make_hostname(name, "masters"),
        "vm_name": name,
        "ip_address": ip,
        "gateway": GATEWAY,
        "dns": DNS
    }

    ansible_inventory["all"]["children"]["masters"]["hosts"][name] = {
        "ansible_host": ip,
        "ansible_user": name
    }

    if master.get("bootstrap", False):
        ansible_inventory["all"]["children"]["masters"]["hosts"][name]["is_bootstrap"] = True

for worker in config.get("workers", []):
    name, ip = worker["name"], worker["ip"]

    terraform_workers[name] = {
        "hostname": make_hostname(name, "workers"),
        "vm_name": name,
        "ip_address": ip,
        "gateway": GATEWAY,
        "dns": DNS
    }

    ansible_inventory["all"]["children"]["workers"]["hosts"][name] = {
        "ansible_host": ip,
        "ansible_user": name
    }

inventory_path = Path("ansible/inventory/hosts.yaml")
inventory_path.parent.mkdir(parents=True, exist_ok=True)
with inventory_path.open("w") as f:
    yaml.dump(ansible_inventory, f, default_flow_style=False, sort_keys=False)

tf_path = Path("terraform/locals.tf")
tf_path.parent.mkdir(parents=True, exist_ok=True)
with tf_path.open("w") as f:
    f.write("locals {\n")
    f.write("  masters = {\n")
    for name, attrs in terraform_masters.items():
        f.write(f'    "{name}" = {{\n')
        for k, v in attrs.items():
            f.write(f'      {k} = "{v}"\n')
        f.write("    }\n")
    f.write("  }\n")

    f.write("  workers = {\n")
    for name, attrs in terraform_workers.items():
        f.write(f'    "{name}" = {{\n')
        for k, v in attrs.items():
            f.write(f'      {k} = "{v}"\n')
        f.write("    }\n")
    f.write("  }\n")
    f.write("}\n")
