#!/bin/sh

export LC_ALL=ja_JP.UTF-8
service postgresql start
cd /var/phoenix/server
mix phx.server
