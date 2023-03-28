#!/bin/bash

(cat /var/log/nginx/access.log /var/log/nginx/access.log.1 && zcat /var/log/nginx/access.log.*.gz) | grep "www.thonis.fr" | goaccess - --log-format=VCOMBINED -o /home/jhanos/public/report.html --geoip-database=/home/jhanos/GeoLite2-Country.mmdb --anonymize-ip
