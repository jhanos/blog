---
title: "Ansible-rulebook, déclencher ansible sur des évenements"
date: 2022-10-26T11:24:09+02:00
draft: false
author: Jhanos
featuredImage: ansible.png
publishDate: 2022-10-27

---

# Ansible-rulebook

## 1. Version Condensée

Ansible-rulebook a été une des grosses annonces de la [Ansible Fest 2022](https://www.ansible.com/ansiblefest).

Ce nouvel outil permet de **déclencher des actions** ansible en se basant sur des **événements**, tel que:
- Executer un playbook à la reception d'un webhook. 
- Executer un playbook quand un fichier est modifié
- Définir un nouveau fact quand on recoit un message dans un bus Kafka

Les rulebook sont décomposés en trois parties:
- Les **sources**, cela corresponds à une pour plusieurs sources d'evenement sur lequel ansible doit écouter (exemple: un bus kafka, un webhook, un fichier pour detecter une modification) 
- Les **rules**, cela corresponds à une combinaison de condition(s) (exemple: si le message kafka contient "trigger" ou alors si le webhook recoit le message "deploy my app")
- Les **actions**, cela corresponds à un playbook (une liste d'actions par exemple) à executer si la condition est remplie.

Il est bien entendu possible de coder son propre déclencheur en python très facilement, les possibilités sont donc immenses.

L'outil a par contre quelques dépendances qui pourrait complexifier son utilisation: 
- ansible-runner, qui sert à executer les playbook
- java et jpy sont utilisés pour le moteur de règles
- Et évidemment les librairies python utilisée dans les script python pour les **sources**

L'outil est disponible sur Github [Ansible rulebook](https://github.com/ansible/ansible-rulebook) et sa documentation est [ici](https://github.com/ansible/ansible-rulebook).

## 2. Version Longue
### Installation

Il faut quelques prérequis pour installer ansible-rulebook (mes tests sont fait sur une machine ubuntu):

```bash
sudo apt install openjdk-17-jdk  python3-dev python3-pip
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PIP_NO_BINARY=jpy
export PATH=$PATH:~/.local/bin
pip install wheel ansible-rulebook ansible ansible-runner aiohttp
ansible-galaxy collection install community.general ansible.eda
```

Voici le détails des prérequis:
- java et jpy ([a Python-Java Bridge](https://github.com/bcdev/jpy)) sont utilisés pour le moteur de règles.
- ansible et ansible-runner servent pour l'execution des playbook
- ansible-rulebook est l'outil en lui meme
- aiohttp ([Asynchronous HTTP Client/Server for asyncio and python](https://docs.aiohttp.org/en/stable/) est utilisé dans les scripts python de sources comme le webhook)
- Et ensuite deux collections ansible community.general ([la collection de base dans ansible](https://github.com/ansible-collections/community.general)) et [ansible.eda](https://github.com/ansible/event-driven-ansible) (Event Driven Ansible) qui est la collection specifique aux évenements et qui contient les plugins de sources et d'actions.

### Utilisation Basique

Pour utliser **ansible-rulebook**, il faut au préalable avoir crée deux fichiers:
- inventory.yaml (un inventaire ansible au format yaml)
- le fichier rulebook.yml qui contiendra nos regles (sources + conditions + actions)

Prenons un inventaire qui ne contient que notre propre machine
```yaml
all:
  hosts:
    localhost:
      ansible_connection: local
```

Prenons le rulebook exemple qui est présenté dans la documentation:
```yaml
- name: Hello Events
  hosts: localhost
  sources:
    - ansible.eda.range:
        limit: 5
  rules:
    - name: Say Hello
      condition: event.i == 1
      action:
        run_playbook:
          name: ansible.eda.hello
```

Son fonctionnement est simple:
- la source: il itère de 1 à 5 
- la condition: si la valeur est 1
- l'action: il affiche hello

Pour l'executer, il faut faire:
```bash
❯ ansible-rulebook -i inventory.yml --rulebook basic-rulebook.yml --verbose
INFO:ansible_rulebook.app:Starting sources
INFO:ansible_rulebook.app:Starting rules
INFO:ansible_rulebook.engine:run_ruleset
INFO:ansible_rulebook.engine:ruleset define: {"name": "Hello Events", "hosts": ["localhost"], "sources": [{"EventSource": {"name": "ansible.eda.range", "source_name": "ansible.eda.range", "source_args": {"limit": 5}, "source_filters": []}}], "rules": [{"Rule": {"name": "Say Hello", "condition": {"AllCondition": [{"EqualsExpression": {"lhs": {"Event": "i"}, "rhs": {"Integer": 1}}}]}, "action": {"Action": {"action": "run_playbook", "action_args": {"name": "ansible.eda.hello"}}}, "enabled": true}}]}
INFO:ansible_rulebook.engine:load source
INFO:ansible_rulebook.engine:load source filters
INFO:ansible_rulebook.engine:Calling main in ansible.eda.range
INFO:ansible_rulebook.engine:Waiting for event from Hello Events
INFO:ansible_rulebook.rule_generator:calling Say Hello
INFO:ansible_rulebook.engine:call_action run_playbook
INFO:ansible_rulebook.engine:substitute_variables [{'name': 'ansible.eda.hello'}] [{'event': {'i': 1}, 'fact': {'i': 1}}]
INFO:ansible_rulebook.engine:action args: {'name': 'ansible.eda.hello'}
INFO:ansible_rulebook.builtin:running Ansible playbook: ansible.eda.hello
INFO:ansible_rulebook.builtin:ruleset: Hello Events, rule: Say Hello
INFO:ansible_rulebook.builtin:Calling Ansible runner

PLAY [hello] *******************************************************************

TASK [debug] *******************************************************************
ok: [localhost] => {
    "msg": "hello"
}

PLAY RECAP *********************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
INFO:ansible_rulebook.engine:Canceling all ruleset tasks
INFO:ansible_rulebook.app:Cancelling event source tasks
INFO:ansible_rulebook.app:Main complete
```
{{< admonition note >}}
Dans notre cas, *ansible-rulebook* s'arrète car le script en source est fini.   
Dans les cas plus classique comme le webhook, il ne s'arrête pas sauf si on lui demande.
{{< /admonition >}}

### Rulebook

#### Sources

{{< admonition note >}}
Les sources correspondent aux différentes possibilités sur lequelles ansible-rulebook peut se déclencher.
{{< /admonition >}}

Chacune des sources suivantes est présente dans la collection ansible.eda, mais il est fort probable que cette liste grandisse prochainement:
- alertmanager - receive events via a webhook from alertmanager
- azure_service_bus - receive events from an Azure service
- file - load facts from YAML files initially and reload when any file changes
- kafka - receive events via a kafka topic
- range - generate events with an increasing index i within a range
- tick - generate events with an increasing index i that never ends
- url_check - poll a set of URLs and send events with their statuses
- watchdog - watch file system and send events when a file status changes
- webhook - provide a webhook and receive events from it

Si on regarde rapidement le plugin de source range.py, on se rends compte qu'il est plutot simple:

```python
"""
range.py

An ansible-events event source plugin for generating events with an increasing index i.

Arguments:
    limit: The upper limit of the range of the index.

Example:
    - ansible.eda.range:
        limit: 5
"""
import asyncio
from typing import Any, Dict

async def main(queue: asyncio.Queue, args: Dict[str, Any]):
    delay = args.get("delay", 0)
    for i in range(int(args["limit"])):
        await queue.put(dict(i=i))
        await asyncio.sleep(delay)

if __name__ == "__main__":
    class MockQueue:
        async def put(self, event):
            print(event)

    asyncio.run(main(MockQueue(), dict(limit=5)))
```

#### Conditions

{{< admonition note >}}
Les conditions servent à determiner si une action est déclenchée.  
{{< /admonition >}}

Voici quelques exemples, les conditions sont tributaires de la ou les sources que vous avez configurée.  
```yaml
# Webhook
condition: event.payload.message == "Deploy my app"

# Alert Manager
condition: event.alert.labels.job == "fastapi" and event.alert.status == "firing"

# Kafka
condition: event.check.metadata.name == "check-fake-app" and event.check.status == 2

# Range
condition: event.i == 1
```

#### Actions


{{< admonition note >}}
Les actions sont les taches à réaliser quand la ou les conditions sont réunies, la tache la plus courante est d'exectuer un playbook.
{{< /admonition >}}

Voici les actions possibles:
- run_playbook - run a playbook using ansible-runner
- set_fact - set a long term fact
- retract_fact - remove a long term fact
- post_event - send a new short term event to the rule engine
- debug - print the current event and facts along with any variables and arguments to the action
- print_event - print the data from the matching event
- noop - do nothing
- shutdown - shutdown the rule engine and terminate ansible-rulebook


### Déclenchement sur un webhook

```yaml
---
- name: Hello Events
  hosts: localhost
  sources:
    - name: listen for alerts
      ansible.eda.webhook:
        host: 0.0.0.0
        port: 8000
  rules:
    - name: Say Hello
      condition: event.payload.message == "Deploy my app"
      action:
        run_playbook:
          name: ansible.eda.hello
```

### Multiple sources
