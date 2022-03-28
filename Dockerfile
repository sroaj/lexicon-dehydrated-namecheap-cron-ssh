FROM tomfun/lexicon-dehydrated-namecheap

RUN apt-get update && apt-get install -y cron openssh-client && \
    which cron && \
    rm -rf /etc/cron.*/* && \
    mkdir -p /root/.ssh && \
    echo "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config && \
    ln -s /run/secrets/user_ssh_key /root/.ssh/id_rsa

COPY entrypoint.sh /entrypoint.sh
COPY crontab /etc/crontab
COPY dehydrated.reload_services.sh reload_services.sh /srv/dehydrated/
# Override default config with config in this repo
COPY config /usr/local/etc/dehydrated/

ENTRYPOINT ["/entrypoint.sh"]

CMD ["cron","-f", "-l", "2"]
