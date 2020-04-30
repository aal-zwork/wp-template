#! /usr/bin/env bash
cur_pwd=$(pwd)
cur_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.."

dockerdir=${2:-$dir}
# set compose name
cd $dockerdir
. .env >/dev/null 2>&1
if [ -n $COMPOSE_PROJECT_NAME ]; then name_compose=$COMPOSE_PROJECT_NAME 
else name_compose=$(basename $dockerdir); fi
defbackupdir=$cur_pwd/${name_compose}_backup

backupdir=${3:-$defbackupdir}

#lastdatt=$(find $backupdir/1* -maxdepth 0 -type d -printf "%f\n" | tail -n 1)
datt=${1:-last}
curdatt=$(date +%s)

cd $cur_pwd
dockerdir=$(realpath $dockerdir)
backupdir=$(realpath $backupdir)
echo $dockerdir
echo $backupdir

from=$backupdir/$datt
echo $from

restore() {
  name=$1
  if [ -f $from/$name-$datt.tar ]; then
    rlogdir=$from/rlog/$curdatt
    mkdir -p $rlogdir
    docker run --rm --volume $name:/to alpine rm -rf /to > $rlogdir/$name-$datt.log 2>&1
    echo "$name-$datt.tar -> $name..."
    docker run --rm --volume $from:/from --volume $name:/to alpine tar xvf /from/$name-$datt.tar -C /to --strip 1 > $rlogdir/$name-$datt.log 2>&1
    docker run --rm --volume $name:/to alpine ls -alh /to > $rlogdir/$name-$datt.log 2>&1
  else echo "ERROR: Can't find tar file $from/$name-$datt.tar" >&2; fi
}

cd $dockerdir
docker-compose config > /dev/null
if ! [ $? -eq 0 ]; then 
  echo "ERROR: it is not docker-compose dir $dockerdir" >&2
  exit 1
fi

docker-compose stop

for j in $(docker volume ls -q | grep ${name_compose}_)
do
  restore $j
done

docker-compose start

echo "Backup resotred from $backupdir/$datt ($(date -s@$datt))"
