#!/usr/bin/with-contenv bash
if [[ -r /usr/local/bin/docker-entrypoint ]]; then
    exec /usr/local/bin/docker-entrypoint
elif [[ -r /docker-entrypoint ]]
    exec /docker-entrypoint
fi
