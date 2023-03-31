---
title: "Ansible-rulebook, How to trigger ansible on events"
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
summary: The pros and cons for ansible-rulebook and How to use it.

---

# Ansible-rulebook

## 1. Short Version

Ansible-rulebook was one of the big announcement in the [Ansible Fest 2022](https://www.ansible.com/ansiblefest).

This new tool allow to **trigger ansible actions** based on events:
- Launch a playbook when a webhook is triggered
- Launch a playbook when a file is changed
- Definie a new fact when a message is receive in a kafka topic

The rukebook are split in three parts:
- **sources**, one or multiple event's sources to listen (example: a kafka's topic, a webhook, a file ) 
- **conditions**, a condition to reach to trigger an action (example: webhook message contains 'hello')
- **actions**, an action to execute (example: launch a playbook, set a fact, ...)

It's possible to create your own source in python easily, so it leads to a lots of possibility.

However, ansible-rulebook has some uncommon requirements:
- ansible-runner, used to launch the playbook
- java and jpy used as rules engine
- And of course all python library used in the **sources**

The tool is available on Github [Ansible rulebook](https://github.com/ansible/ansible-rulebook) and its documentation is  [here](https://github.com/ansible/ansible-rulebook).

## 2. Long Version
### Install


ansible-rulebook need some prerequisites (my tests are done on ubuntu)

```bash
sudo apt install openjdk-17-jdk python3-dev python3-pip
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PIP_NO_BINARY=jpy
export PATH=$PATH:~/.local/bin
pip install wheel ansible-rulebook ansible ansible-runner aiohttp
ansible-galaxy collection install community.general ansible.eda
```

Requirements details:
- java and jpy ([a Python-Java Bridge](https://github.com/bcdev/jpy)) for the engine rules.
- ansible and ansible-runner for the playbook execution
- ansible-rulebook the main tool
- aiohttp ([Asynchronous HTTP Client/Server for asyncio and python](https://docs.aiohttp.org/en/stable/) ), used in official sources like 'webhook'
- And then 2 collections community.general ([based ansible collection](https://github.com/ansible-collections/community.general)) and [ansible.eda](https://github.com/ansible/event-driven-ansible) (Event Driven Ansible) which is the collection with sources' plugins and actions.


Current versions for this test:
- python 3.8.10
- openjdk version 17.0.5
- ansible-rulebook 0.9.4
- ansible-runner 2.2.1
- ansible 2.13.5

### Basic usage

**ansible-rulebook** needs two files to work:
- inventory.yaml (an ansible inventory in yaml)
- rulebook.yml ( a file with our rules (sources + conditions + actions)

We use localhost as inventory:
```yaml
all:
  hosts:
    localhost:
      ansible_connection: local
```

And for this example, we take the rulebook inside the documentation
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

With explanation:
- source: iterate from 1 to 5 
- condition: if the value is 1
- action: print hello

In order to use it, we just have to launch:
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
In this case, *ansible-rulebook* stop, because the source finish.   
In common case, it runs forever except if the action request to stop
{{< /admonition >}}

### Rulebook

#### Sources

{{< admonition note >}}
Sources : the multiple possibilities to listen to trigger something
{{< /admonition >}}

You can find below, the sources inside the collection ansible.eda:

- alertmanager - receive events via a webhook from alertmanager
- azure_service_bus - receive events from an Azure service
- file - load facts from YAML files initially and reload when any file changes
- kafka - receive events via a kafka topic
- range - generate events with an increasing index i within a range
- tick - generate events with an increasing index i that never ends
- url_check - poll a set of URLs and send events with their statuses
- watchdog - watch file system and send events when a file status changes
- webhook - provide a webhook and receive events from it

With a quick look on the range python script, it seems easy to create our own source.

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
Actions: Trigger what you need to happen should a condition be met. Some of the current actions are:
{{< /admonition >}}

Actions' list:
- run_playbook - run a playbook using ansible-runner
- set_fact - set a long term fact
- retract_fact - remove a long term fact
- post_event - send a new short term event to the rule engine
- debug - print the current event and facts along with any variables and arguments to the action
- print_event - print the data from the matching event
- noop - do nothing
- shutdown - shutdown the rule engine and terminate ansible-rulebook

### Trigger from a webhook

In this example:
- source: ansible-rulebook listen for message on all ip and on the port 8000.
- condition: if the  message is "Remediation1"
- action: the playbook 'myplaybook' will be exexuted with ansible-playbook and ansible-runner


We use the rulebook below:
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

We start `ansible-rulebook`:
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

In another terminal, I request the webhook.
```bash
❯ curl -H 'Content-Type: application/json' -d '{"message": "Remediation1"}' 127.0.0.1:8000/webhook
```

And the playbook runs:
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

We can also define multiple sources:

{{< admonition note >}}
If one of the sources stop, all the rulebook stop
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

To Summerize, this tool seems really promising and the possibilities seems infinite:
- Trigger a playbook from outside, when ssh is not reachable for security reason
- Trigger a playbook based on message on slack/mattermost on dev platform
- Trigger playbook to wake up applications, previously stop for energy saving

However, i am relunctant due to:
- The dependencies: java
- The tool is very recent and not mature, few contributors for the moment
