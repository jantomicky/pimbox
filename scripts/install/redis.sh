#!/bin/bash

CONFIG_REDIS="/etc/redis/redis.conf"

echo "Installing Redis…"
apt-get install -y redis-server redis-tools

echo "Configuring Redis…"
redis-cli config set maxmemory 1gb
redis-cli config set maxmemory-policy volatile-lru
redis-cli config set save ""
redis-cli config rewrite

echo "Redis installed."
