#! /usr/bin/env bash
cur_pwd=$(pwd)
cur_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/.."

dockerdir=${1:-$cur_dir}
# set compose name
cd $dockerdir
. .env >/dev/null 2>&1
if [ -n $COMPOSE_PROJECT_NAME ]; then name_compose=$COMPOSE_PROJECT_NAME 
else name_compose=$(basename $dockerdir); fi
defbackupdir=$cur_pwd/${name_compose}_backup

datt=$(date +%s)
backupdir=${2:-$defbackupdir}

cd $cur_pwd
dockerdir=$(realpath $dockerdir)
backupdir=$(realpath $backupdir)
echo $dockerdir
echo $backupdir

tmpdir=$backupdir/tmp
echo $tmpdir

backup() {
  name=$1
  echo "$name -> $name-$datt.tar(log)..."
  docker run --rm --volume $name:/from --volume $tmpdir:/to alpine tar cvf /to/$name-$datt.tar /from > $tmpdir/$name-$datt.log 2>&1
}

cd $dockerdir
docker-compose config > /dev/null
if ! [ $? -eq 0 ]; then 
  echo "ERROR: it is not docker-compose dir $dockerdir" >&2
  exit 1
fi

mkdir -p $backupdir
mkdir -p $tmpdir

docker-compose stop 

for j in $(docker volume ls -q | grep ${name_compose}_)
do
  backup $j
done

docker-compose start

echo "Backup saved to $backupdir/$datt ($(date -s@$datt))"
mkdir -p $backupdir/$datt 
mv $tmpdir/*-$datt.tar $backupdir/$datt/
mv $tmpdir/*-$datt.log $backupdir/$datt/
cd $backupdir
rm -f last
ln -sf $datt last
