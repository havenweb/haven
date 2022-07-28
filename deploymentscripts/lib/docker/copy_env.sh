#!/bin/bash
declare -p | grep -E 'RUBY|GEM|BUNDLE|RAILS|HAVEN|PATH' > /root/container.env
