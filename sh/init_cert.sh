#! /usr/bin/env bash
cur_pwd=$(pwd)
dockerdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.."

echo $dockerdir
cd $dockerdir
. .env >/dev/null 2>&1
if [ -n $COMPOSE_PROJECT_NAME ]; then name_compose=$COMPOSE_PROJECT_NAME 
else name_compose=$(basename $dockerdir); fi

if [ ! -f .init_cert.env ]; then echo ".init_cert.env not found"; exit 1; fi
. .init_cert.env

if [ -n "$1" ] && [ "$1" = "dr" ]; then dry_run="--dry-run"; fi

if [ -z "$CERT_DNSS" ] || [ -z "$CERT_EMAIL" ]; then
  echo "CERT_DNSS and CERT_EMAIL not set"
  exit 2
fi

echo "server_name $CERT_DNSS;" > ./nginx-conf/site/name.conf

first_dns=$(echo $CERT_DNSS | sed 's/\s.\+//g')
echo "ssl_certificate /etc/letsencrypt/live/$first_dns/fullchain.pem;" > ./nginx-conf/site/ssl-cert.conf
echo "ssl_certificate_key /etc/letsencrypt/live/$first_dns/privkey.pem;" >> ./nginx-conf/site/ssl-cert.conf
curl -sSLo ./nginx-conf/site/options-ssl-nginx.conf https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf

dns_for_certbot=$(echo $CERT_DNSS | sed 's/\s/,/g')
docker-compose -f docker-compose.yml -f docker-compose.init_cert.yml up -d
docker-compose run cbot certonly $dry_run --webroot -w /var/lib/letsencrypt --email $CERT_EMAIL --agree-tos --no-eff-email --staging -d ${dns_for_certbot}
docker-compose run cbot certonly $dry_run --webroot -w /var/lib/letsencrypt --email $CERT_EMAIL --agree-tos --no-eff-email --force-renewal -d ${dns_for_certbot}

docker run --rm -v $(echo $(pwd)/nginx-conf):/from --volume ${name_compose}_wsrv_etc:/to alpine cp -rf /from/nginx.conf.ssl /to/nginx.conf
docker run --rm -v $(echo $(pwd)/nginx-conf):/from --volume ${name_compose}_wsrv_etc:/to alpine cp -rf /from/site /to/site

docker-compose up -d
