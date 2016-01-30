#!/bin/bash

cp ./ovpn.service /etc/systemd/system/ovpn.service
chmod 664 /etc/systemd/system/ovpn.service

systemctl daemon-reload
systemctl enable ovpn.service
