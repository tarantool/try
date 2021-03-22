#!/usr/bin/env bash


if [ -n "${PRODUCTION}" ]; then
  iptables-restore < /tmp/iptables.rules
fi

gosu tarantool cartridge start
