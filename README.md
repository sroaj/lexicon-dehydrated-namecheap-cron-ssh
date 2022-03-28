# lexicon-dehydrated-namecheap-cron-ssh

Based on:
 - https://github.com/tomfun/lexicon-dehydrated-namecheap
 - https://blog.thesparktree.com/cron-in-docker
 - https://mharrison.org/post/bashfunctionoverride/ 
 - https://medium.com/trabe/use-your-local-ssh-keys-inside-a-docker-container-ea1d117515dc

## Why

tomfun's lexicon-dehydrated-namecheap works great and I wanted to run it periodically to automate my wildcard domain dns-01 verification. Which I then require to propagate certificates down other ssh enabled hosts.

## Usage

Use this with docker-compose

```yaml
version: "3.9"
services:
  dehydrated:
    container_name: dehydrated
    build:
      context: https://github.com/sroaj/lexicon-dehydrated-namecheap-cron-ssh.git#main
    init: true
    environment:
      EMAIL: "<put your email here>"
      LEXICON_NAMECHEAP_USERNAME: "<put namecheap API username here>"
      LEXICON_NAMECHEAP_TOKEN: "<put namecheap API token here>"
# Some services only support RSA keys. i.e. ESXI 7.0
#     ALGORITHM: rsa
    volumes:
      - 'data:/data'
# Dependent on your ssh key setup. You may want to mount to /root/.ssh to have full control
#     - '/root/.ssh/ssl_id_rsa:/root/.ssh/id_rsa:ro'
volumes:
  data:
```

Add ```/data/domains.txt``` with domains:

```txt
*.example.com
```

### First time

After your start the container. Suppose the container has the name ```dehydrated```:

```bash
docker exec -it dehydrated /srv/dehydrated/dehydrated --register --accept-terms
```

### Auto propogation

Suppose you want certificates to be copied to and installed in a specific ssh-able host.

Create a ```/data/hostlist.txt``` with the following format:

```
[user@]hostname|ip [command to run]
```

i.e.

```
172.254.0.2
freenas.example.com
edgemax.example.com /config/auth/letsencrypt.sh
someuser@esxi.example.com /vmfs/volumes/persistent/install.sh
```

The ```cert.pem``` and ```fullchain.pem``` will be ```scp```-ed to the ```hostname``` and placed at the default home directory. 

The ```command to run```, or ```./letsencrypt.sh``` if omitted, is executed on the host with args as follows:

 - $0: Program name
 - $1: Certificate file name
 - $2: Full chain file name
 - stdin: Private key
 - stdout: Docker stdout
 - cwd: home directory

The certificate and chain files are not automatically cleaned up. So if you want them gone you should ```rm``` them.

#### Unifi Edgemax

Here's an example ```letsencrypt.sh``` to install certificate onto Unifi's Edgemax devices:

```bash
#!/bin/bash
HOSTNAME=$(hostname)

echo "Now executing on ${HOSTNAME}:$0 with args: $1 $2"

echo "backing up old pem"

sudo cp /etc/lighttpd/server.pem /etc/lighttpd/server.pem.old

echo "Writing private key to server.pem"

cat > server.pem

echo "Appending certificate to server.pem"

cat ${1} >> server.pem
cat ${2} >> server.pem

echo "Moving server.pem to /etc/lighttpd/server.pem"

sudo mv server.pem /etc/lighttpd/server.pem
sudo chown root:root /etc/lighttpd/server.pem

echo "Killing webserver"

sudo kill -SIGINT $(cat /var/run/lighttpd.pid)

echo "Starting webserver"

sudo /usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf
```

#### ESXI

Here's an example ```letsencrypt.sh``` to install certificate to ESXI:

```bash
#!/bin/sh
HOSTNAME=$(hostname)
echo "Now executing on ${HOSTNAME}:$0 with args: $1 $2"

CRT=/etc/vmware/ssl/rui.crt
KEY=/etc/vmware/ssl/rui.key

echo "Backing up ${CRT} and ${KEY}"

mv -v "${CRT}" ${CRT}.bak
mv -v "${KEY}" ${KEY}.bak

echo "Copying ${1} to ${CRT}"
cp -v "${1}" "${CRT}"

echo "Writing stdin to ${KEY}"
cat > "${KEY}"

echo "Restarting hostd"
/etc/init.d/hostd restart
```

#### TrueNAS

Here's an example ```letsencrypt.sh``` using [deploy_freenas.py](https://github.com/danb35/deploy-freenas) to install cerficates to TrueNAS:

```bash
#!/bin/bash
HOSTNAME=$(hostname)
echo "Now executing on ${HOSTNAME}:$0 with args: $1 $2"
echo "Running deploy_freenas.py"
python3 deploy_freenas.py
```

With a ```deploy_config``` of:
```ini
[deploy]
api_key = <Your freenas api key>
privkey_path = /dev/stdin
fullchain_path = cert.pem
```
