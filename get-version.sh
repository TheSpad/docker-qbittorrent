#! /bin/bash

APP_VERSION=$(curl -sX GET "https://api.github.com/repos/qbittorrent/qbittorrent/tags" | jq -r '.[] | .name' | grep -P -m 1 '(rc|beta|alpha)');

printf "%s" "${APP_VERSION}"