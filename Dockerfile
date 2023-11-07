FROM analogj/lexicon:latest

COPY --from=tomfun/lexicon-dehydrated-namecheap /srv/dehydrated/config /srv/dehydrated/

RUN apt update \
    && apt install -y bsdmainutils \
    && apt-get clean \
    && pip install dns-lexicon[namecheap] \
    && apt-get install -y cron openssh-client && \
    which cron && \
    rm -rf /etc/cron.*/* && \
    mkdir -p /root/.ssh && \
    echo "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config && \
    ln -s /run/secrets/user_ssh_key /root/.ssh/id_rsa

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
COPY crontab /etc/crontab
COPY dehydrated.reload_services.sh reload_services.sh /srv/dehydrated/
# Override default config with config in this repo
COPY config /usr/local/etc/dehydrated/

VOLUME /data

ENV PROVIDER=namecheap

ENV PROVIDER_UPDATE_DELAY=300

ENTRYPOINT ["/entrypoint.sh"]

CMD ["cron","-f", "-l", "2"]
