#!/bin/bash

function add_repo_postgres {
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7FCC7D46ACCC4CF8
}

function install_barman {
  sudo apt-get install barman -y
}
function copy_keys {
  echo "---Copying public key to authorized"

  if [ ! -d /var/lib/barman/.ssh ]; then
    echo "---creating directory---"
    sudo su - barman -c "mkdir -p /var/lib/barman/.ssh"
    sudo su - barman -c "chmod 700 /var/lib/barman/.ssh"
    echo "Directory Created>>>"
  fi

  sudo su - barman -c "cat /tmp/postgres_rsa.pub >> /var/lib/barman/.ssh/authorized_keys"
  echo "---modifying permission on public key---"
  sudo su - barman -c "chmod 600 /var/lib/barman/.ssh/authorized_keys"
  echo "---copying keys---"
  sudo cp /tmp/postgres_rsa /var/lib/barman/.ssh/id_rsa
  sudo su - barman -c "cp /tmp/barman_rsa.pub /var/lib/barman/.ssh/id_rsa.pub"
  sudo chown barman /var/lib/barman/.ssh/id_rsa
  sudo su - barman -c "chmod 600 /var/lib/barman/.ssh/id_rsa"
  echo "private keys copied"
  sudo ls -l /var/lib/barman/.ssh/

}

function create_cron_job {
  echo "---Creating cron job---"
  sudo su - barman -c "barman receive-wal --create-slot mrm-postgresql-server"
  sudo crontab -u barman /tmp/cron-job
}
function replace_config_files {
  echo "---moving barman config files---"
  sudo mv /tmp/barman.conf /etc/barman.conf
}
function add_db_details {
  sudo su - barman -c "echo \"172.16.13.130:5432:*:barmanstreamer:$1\" > ~/.pgpass"
  sudo su - barman -c "chmod 400 ~/.pgpass"
  sudo chown barman:barman /var/lib/barman/.pgpass

}
function main {
  add_repo_postgres
  install_barman
  copy_keys
  replace_config_files
  add_db_details $1
  create_cron_job
}
main $1
