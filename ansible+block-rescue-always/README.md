```
ansible-playbook -vvv main.yml
ansible-playbook 2.10.1
  config file = /home/asd/_git/RESEARCH/ansible+block-rescue-always/ansible.cfg
  configured module search path = ['/home/asd/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /home/asd/3.7/lib/python3.7/site-packages/ansible
  executable location = /home/asd/3.7/bin/ansible-playbook
  python version = 3.7.8 (default, Jun 27 2020, 09:38:56) [GCC 9.3.0]
Using /home/asd/_git/RESEARCH/ansible+block-rescue-always/ansible.cfg as config file
host_list declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
Skipping due to inventory source not existing or not being readable by the current user
script declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
auto declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
Skipping due to inventory source not existing or not being readable by the current user
yaml declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
Skipping due to inventory source not existing or not being readable by the current user
ini declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
Skipping due to inventory source not existing or not being readable by the current user
toml declined parsing /etc/ansible/hosts as it did not pass its verify_file() method
redirecting (type: callback) ansible.builtin.yaml to community.general.yaml
redirecting (type: callback) ansible.builtin.yaml to community.general.yaml

PLAYBOOK: main.yml *************************************************************
1 plays in main.yml

PLAY [localhost] ***************************************************************
META: ran handlers

TASK [this will succeed] *******************************************************
task path: /home/asd/_git/RESEARCH/ansible+block-rescue-always/main.yml:5
included: /home/asd/_git/RESEARCH/ansible+block-rescue-always/included_task.yml for localhost => (item=invalid)

TASK [block] *******************************************************************
task path: /home/asd/_git/RESEARCH/ansible+block-rescue-always/included_task.yml:3
fatal: [localhost]: FAILED! => 
  msg: |-
    An unhandled exception occurred while running the lookup plugin 'template'. Error was a <class 'ansible.errors.AnsibleError'>, original message: template error while templating string: unexpected char '$' at 18. String: ---
    index: "1"
    {{ $%%&^*%*& "kek" }}

TASK [rescue] ******************************************************************
task path: /home/asd/_git/RESEARCH/ansible+block-rescue-always/included_task.yml:8
ok: [localhost] => changed=false 
  ansible_facts:
    somefact: |-
      ---
      index: "1"
      {{ $%%&^*%*& "kek" }}

TASK [always] ******************************************************************
task path: /home/asd/_git/RESEARCH/ansible+block-rescue-always/included_task.yml:13
ok: [localhost] => 
  somefact: |-
    ---
    index: "1"
    {{ $%%&^*%*& "kek" }}

TASK [this will fail] **********************************************************
task path: /home/asd/_git/RESEARCH/ansible+block-rescue-always/main.yml:11
included: /home/asd/_git/RESEARCH/ansible+block-rescue-always/included_task.yml for localhost => (item=invalid)

TASK [block] *******************************************************************
task path: /home/asd/_git/RESEARCH/ansible+block-rescue-always/included_task.yml:3
fatal: [localhost]: FAILED! => 
  msg: |-
    An unhandled exception occurred while running the lookup plugin 'template'. Error was a <class 'ansible.errors.AnsibleError'>, original message: template error while templating string: unexpected char '$' at 18. String: ---
    index: "1"
    {{ $%%&^*%*& "kek" }}

TASK [rescue] ******************************************************************
task path: /home/asd/_git/RESEARCH/ansible+block-rescue-always/included_task.yml:8
ok: [localhost] => changed=false 
  ansible_facts:
    somefact: |-
      ---
      index: "1"
      {{ $%%&^*%*& "kek" }}

TASK [always] ******************************************************************
task path: /home/asd/_git/RESEARCH/ansible+block-rescue-always/included_task.yml:13
fatal: [localhost]: FAILED! => 
  msg: |-
    An unhandled exception occurred while templating '---
    index: "1"
    {{ $%%&^*%*& "kek" }}'. Error was a <class 'ansible.errors.AnsibleError'>, original message: template error while templating string: unexpected char '$' at 18. String: ---
    index: "1"
    {{ $%%&^*%*& "kek" }}

NO MORE HOSTS LEFT *************************************************************

PLAY RECAP *********************************************************************
localhost                  : ok=5    changed=0    unreachable=0    failed=1    skipped=0    rescued=2    ignored=0   
```
