#! /usr/bin/env bash
cur_pwd=$(pwd)
dockerdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.."

echo $dockerdir
cd $dockerdir

if [ ! -f .init_cert.env ]; then echo ".init_cert.env not found"; exit 1; fi
. .init_cert.env

if [ -n $1 ] && [ "$1" = "dr" ]; then dry_run="--dry-run"; fi

if [ -z $CERT_DNSS ] || [ -z $CERT_EMAIL ]; then
  echo "CERT_DNSS and CERT_EMAIL not set"
  exit 2
fi

echo "server_name $CERT_DNSS;" > ./nginx-conf/site/name.conf

dns_for_certbot=$(echo $CERT_DNSS | sed 's/\s/,/g')
docker-compose -f docker-compose.yml -f docker-compose.init_cert.yml up -d
docker-compose run cbot certonly $dry_run --webroot -w /var/lib/letsencrypt --email $CERT_EMAIL --agree-tos --no-eff-email -d ${dns_for_certbot}
# --staging
#docker-compose run cbot certonly $dry_run --webroot -w /var/lib/letsencrypt --email $CERT_EMAIL --agree-tos --no-eff-email --force-renewal -d ${dns_for_certbot}
docker-compose up -d
