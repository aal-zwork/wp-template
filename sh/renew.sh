#! /usr/bin/env sh
cur_pwd=$(pwd)
dockerdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.."

echo $dockerdir
cd $dockerdir

docker-compose --no-ansi --rm run cbot renew && kill -s SIGHUP wsrv
docker sysmtem prune -af
