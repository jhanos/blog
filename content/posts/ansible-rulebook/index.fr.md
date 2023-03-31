---
title: "Ansible-rulebook, comment déclencher ansible sur des événements"
date: 2022-10-26T11:24:09+02:00
draft: false
author: Jhanos
featuredImage: ansible.webp
publishDate: 2022-10-27
categories:
- Automation
tags:
- ansible
- automation
summary: Les apports d'ansible-rulebook et comment l'utiliser.

---

# Ansible-rulebook

## 1. Version Condensée

Ansible-rulebook a été une des grosses annonces de la [Ansible Fest 2022](https://www.ansible.com/ansiblefest).

Ce nouvel outil permet de **déclencher des actions** ansible en se basant sur des **événements**, tel que:
- Exécuter un playbook à la réception d'un webhook. 
- Exécuter un playbook quand un fichier est modifié
- Définir un nouveau fact quand on reçoit un message dans un bus Kafka

Les rulebook sont décomposés en trois parties:
- Les **sources**, cela correspond à une pour plusieurs sources d'événement sur lequel ansible doit écouter (exemple: un bus kafka, un webhook, un fichier pour detecter une modification) 
- Les **conditions**, cela correspond à une des modalités nécessaire pour le déclenchement des actions (exemple: si le message kafka contient "trigger" ou alors si le webhook reçoit le message "deploy my app")
- Les **actions**, cela correspond à une ou plusieurs actions (par exemple un playbook) à éxecuter si la condition est remplie.

Il est bien entendu possible de coder son propre déclencheur en python très facilement, les possibilités sont donc immenses.

L'outil a par contre quelques dépendances qui pourraient complexifier son utilisation: 
- ansible-runner, qui sert à executer les playbook
- java et jpy sont utilisés pour le moteur de règles
- Et évidemment les librairies python utilisée dans les scripts python pour les **sources**

L'outil est disponible sur Github [Ansible rulebook](https://github.com/ansible/ansible-rulebook) et sa documentation est [ici](https://github.com/ansible/ansible-rulebook).

## 2. Version Longue
### Installation


Il faut quelques prérequis pour installer ansible-rulebook. (mes tests sont faits sur une machine ubuntu) :

```bash
sudo apt install openjdk-17-jdk python3-dev python3-pip
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PIP_NO_BINARY=jpy
export PATH=$PATH:~/.local/bin
pip install wheel ansible-rulebook ansible ansible-runner aiohttp
ansible-galaxy collection install community.general ansible.eda
```

Voici le détail des prérequis:
- java et jpy ([a Python-Java Bridge](https://github.com/bcdev/jpy)) sont utilisés pour le moteur de règles.
- ansible et ansible-runner servent pour l'execution des playbook
- ansible-rulebook est l'outil en lui-même
- aiohttp ([Asynchronous HTTP Client/Server for asyncio and python](https://docs.aiohttp.org/en/stable/) est utilisé dans les scripts python de sources comme le webhook)
- Et ensuite deux collections ansible community.general ([la collection de base dans ansible](https://github.com/ansible-collections/community.general)) et [ansible.eda](https://github.com/ansible/event-driven-ansible) (Event Driven Ansible) qui est la collection specifique aux évenements et qui contient les plugins de sources et d'actions.


Voici les versions des composants installés:
- python 3.8.10
- openjdk version 17.0.5
- ansible-rulebook 0.9.4
- ansible-runner 2.2.1
- ansible 2.13.5

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
Dans notre cas, *ansible-rulebook* s'arrète, car le script en source est fini.   
Dans les cas plus classiques comme le webhook, il ne s'arrête pas sauf si on lui demande.
{{< /admonition >}}

### Rulebook

#### Sources

{{< admonition note >}}
Les sources correspondent aux différentes possibilités sur lequelles ansible-rulebook peut se déclencher.
{{< /admonition >}}

Chacune des sources suivantes est présente dans la collection ansible.eda, mais il est fort probable que cette liste grandisse prochainement:
- alertmanager - recevoir un événement provenant d'alertmanager via un webhook
- azure_service_bus - recevoir un événement depuis le service Azure
- file - charger des facts depuis un fichier yaml et recharger en cas de changement dans le fichier yaml
- kafka - recevoir un événement depuis un topic kafka
- range - générer un événement avec une boucle qui incrémente i jusqu'a une limite (range en python)
- tick - générer un événement avec une boucle infinie avec un i qui croit
- url_check - requête une url et envoie un message selon leur status
- watchdog - surveille un fichier et envoie un événement si il est modifié
- webhook - fournit un webhook et attend de recevoir un evenement dessus

Si on regarde rapidement le plugin de source range.py, on se rend compte qu'il est plutot simple:

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

Voici quelques exemples, les conditions sont tributaires de la ou les sources que vous avez configurées. 
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
- run_playbook - lance un playbook ansible en utilisant ansible-runner
- set_fact - definit un fact
- retract_fact - suprime un fact
- post_event - envoie un nouvel evenement dans le moteur de règles
- debug - affiche les evenements, les facts et les variables liées à cette action
- print_event - afficher les données de l'evenement ciblé
- noop - ne rien faire
- shutdown - arreter ansible-rulebook


### Déclenchement sur un webhook

Dans cet exemple: 
- La source: ansible-rulebook va attendre de recevoir un message sur le webhook (qui écoute sur toutes les ip de la machine et sur le port 8000).
- La condition: si le message est "Remediation1"
- L'action: le playbook 'myplaybook' sera executé via ansible-playbook et ansible-runner


```yaml
---
- name: Deploy Remediation
  hosts: localhost
  sources:
    - name: listen for alerts
      ansible.eda.webhook:
        host: 0.0.0.0
        port: 8000
  rules:
    - name: Remediate server
      condition: event.payload.message == "Remediation1"
      action:
        run_playbook:
          name: myplaybook.yml
```

Nous executons `ansible-rulebook`:
```bash
❯ ansible-rulebook -i inventory.yml --rulebook rulebook.yml --verbose
INFO:ansible_rulebook.app:Starting sources
INFO:ansible_rulebook.app:Starting rules
INFO:ansible_rulebook.engine:run_ruleset
INFO:ansible_rulebook.engine:ruleset define: {"name": "Deploy Remediation", "hosts": ["localhost"], "sources": [{"EventSource": {"name": "listen for alerts", "source_name": "ansible.eda.webhook", "source_args": {"host": "0.0.0.0", "port": 8000}, "source_filters": []}}], "rules": [{"Rule": {"name": "Remediate server", "condition": {"AllCondition": [{"EqualsExpression": {"lhs": {"Event": "payload.message"}, "rhs": {"String": "Remediation1"}}}]}, "action": {"Action": {"action": "run_playbook", "action_args": {"name": "myplaybook.yml"}}}, "enabled": true}}]}
INFO:ansible_rulebook.engine:load source
INFO:ansible_rulebook.engine:load source filters
INFO:ansible_rulebook.engine:Calling main in ansible.eda.webhook
INFO:ansible_rulebook.engine:Waiting for event from Deploy Remediation
```

Dans un autre terminal, nous requêtons le webhook.
```bash
❯ curl -H 'Content-Type: application/json' -d '{"message": "Remediation1"}' 127.0.0.1:8000/webhook
```

Nous voyons le playbook s'executer:
```bash
❯ ansible-rulebook -i inventory.yml --rulebook rulebook.yml --verbose
INFO:ansible_rulebook.app:Starting sources
INFO:ansible_rulebook.app:Starting rules
...
INFO:aiohttp.access:127.0.0.1 [18/Nov/2022:14:08:48 +0000] "POST /webhook HTTP/1.1" 200 157 "-" "curl/7.68.0"
INFO:ansible_rulebook.rule_generator:calling Remediate server
INFO:ansible_rulebook.engine:call_action run_playbook
INFO:ansible_rulebook.engine:substitute_variables [{'name': 'myplaybook.yml'}] [{'event': {'payload': {'message': 'Remediation1'}, 'meta': {'headers': {'Accept': '*/*', 'User-Agent': 'curl/7.68.0', 'Host': '127.0.0.1:8000', 'Content-Length': '27', 'Content-Type': 'application/json'}, 'endpoint': 'webhook'}}, 'fact': {'payload': {'message': 'Remediation1'}, 'meta': {'headers': {'Accept': '*/*', 'User-Agent': 'curl/7.68.0', 'Host': '127.0.0.1:8000', 'Content-Length': '27', 'Content-Type': 'application/json'}, 'endpoint': 'webhook'}}}]
INFO:ansible_rulebook.engine:action args: {'name': 'myplaybook.yml'}
INFO:ansible_rulebook.builtin:running Ansible playbook: myplaybook.yml
INFO:ansible_rulebook.builtin:ruleset: Deploy Remediation, rule: Remediate server
INFO:ansible_rulebook.builtin:Calling Ansible runner

PLAY [test] ********************************************************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [ansible.builtin.shell] ***************************************************
changed: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
``` 

### Multiple sources

Il est aussi possible de définir plusieurs sources simultanées:

{{< admonition note >}}
Si une des sources s'arrête, tout le rulebook s'arrete, ce qui est le cas dans notre exemple
{{< /admonition >}}

```yaml
---
- name: Multiple Sources
  hosts: localhost
  sources:
    - name: listen for alerts
      ansible.eda.webhook:
        host: 0.0.0.0
        port: 8000
    - name: range
      ansible.eda.range:
        limit: 20
        delay: 1
  rules:
    - name: trigger on range
      condition: event.i == 2
      action:
        debug:
    - name: trigger on webhook
      condition: event.payload.message == "Remediation1"
      action:
        debug:
```

### Conclusion

En conclusion, l'outil semble vraiment prometteur et les possiblités semblent incroyables, quelques idées en vrac:
- Déclencher les playbook à distance quand il n'est pas possible d'executer ansible-playbook à travers ssh pour des raisons de sécurité
- Déclencher ansible-playbook avec un message sur un canal mattermost/slack sur une plateforme de dev
- Déclencher des playbook en chaine pour activer des services endormis pour économiser de l'energie.

Par contre, je vois quelques freins à l'adoption de ce produit:
- Les dépendances dont java
- L'outil est encore jeune, il faut souvent aller voir dans le code pour comprendre les options possibles.
