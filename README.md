# Georgian Budget

This api application visualizes the national budget of the Republic of Georgia.

## Get Started
1. Setup .env file
  1. `cp .env.example .env`
  2. Add Secrets (use `rake secret` to generate values)
  3. Use `postgres` as the value for `DB_USER` and `TEST_DB_USER`
  4. Set database names for `DB_NAME` and `TEST_DB_NAME`, such as 'budget_dev' and 'budget_test'
1. Install [docker](https://www.docker.com/products/overview) and [docker-compose](https://docs.docker.com/compose/install/)
1. `docker-compose build` (takes a while)
TODO ubuntu related issue
1. `docker-compose up`
1. `docker-compose run api rake db:create db:migrate db:seed`
1. Add budget data to database. Two options:
  1. Restore the dev database from a db dump:
    1. `docker-compose ps` ---> get the name of the `db` container
    1. `docker cp /path/to/db/file db_container_name:/tmp/backup.sql`
    1. `docker-compose exec db pg_restore --clean --no-owner -d "dev_db_name" -U "postgres" /tmp/backup.sql`
  1. If you don't have a dump file to restore from, you can run the budget uploader (consult separate section below).
1. Go to [localhost:3000](http://localhost:3000) or start using the API :)

## Run the budget uploader

1. Sync the local budget files repo with master: `docker-compose run api rake budget_data:sync_with_repo`
1. Run the uploader (takes a long time): `docker-compose run api rake budget_data:upload`

## Deploy (or run any mina command) from within `docker-compose exec api bash` container

The api container is not configured by default to work for deploying, so you will have to do a little bit of configuration in order to do so. This section is intended to make that configuration easier.

Ideally, this is only a temporary solution until we figure out how to deploy with docker.

NOTE: The below commands will only work if the container you are setting up to deploy from is named `georgianbudgetapi_api_1`. If it has a different name, then use it below in the `docker cp` commands.

1. Copy your global gitignore into the `api` container (called from host):
  ```
  docker cp ~/.gitignore_global georgianbudgetapi_api_1:/root/
  ```
  (on ubuntu .gitignore_global step is skipped)
2. Run these commands from within the `api` container(called from api container):
  ```
  git config --global core.excludesfile /root/.gitignore_global

  bundle_path=$(which bundle)
  sed -i -e "s/activate_bin_path/bin_path/g" $bundle_path

  mkdir -p /root/.ssh

  apt-get -y install rsync
  ```

  In order: configure git to use .gitignore_global; fix bundle issue described [here](https://github.com/bundler/bundler/issues/4602#issuecomment-233619696); create .ssh directory if it doesn't exist; install rsync, which is a dependency of the deploy process.

3. Make sure your local user has an ssh key at ~/.ssh/id_rsa and ~/.ssh/id_rsa.pub. (called from host)
  ```
  docker cp ~/.ssh/id_rsa georgianbudgetapi_api_1:/root/.ssh/
  docker cp ~/.ssh/id_rsa.pub georgianbudgetapi_api_1:/root/.ssh/
  ```

4. Add your ssh key to the container's ssh-agent so that it doesn't ask for your passphrase when you deploy. You will have to enter your ssh key's passphrase. (called from api container)

  ```
  eval "$(ssh-agent -s)"
  eval ssh-agent
  ssh-add ~/.ssh/id_rsa
  ```

5. Continue with deploy as usual

## Transfer Postgres database

1. Find the database container name: `docker-compose ps`
2. Log into the db container: `docker exec -i -t {container-id} /bin/bash`
3. Dump the database: `pg_dump -Fc -U postgres -O budget_staging_dev > tmp/budget_dev.sql`
4. Exit the db container: `exit`
5. Copy out of db container: `docker cp {container-id}:tmp/budget_dev.sql tmp/`
6. Copy to server: `scp tmp/budget_dev.sql {user_name}@{server_name}:tmp/`
7. Restore: `pg_restore --clean --no-owner -d "budget-staging" -U "budget-staging" tmp/budget_dev.sql`

## Docker Cheat Sheet

This is a cheat sheet for JumpStart's Rails docker projects. If you want to truly understand what's going on here, consult the Docker documentation and work through their tutorials.

### Build (or rebuild) images

`docker-compose build`

### Start up project

`docker-compose up`

### Bundler

If you're missing a gem, you don't want to rebuild the docker api image — that takes too long, as it forces docker to install all the gems. Instead:

`docker-compose run api bundle install`

Or to update:

`docker-compose run api bundle update`

### Open bash session in api container

If you find yourself typing a lot of commands prefixed by `docker-compose run api`, you can open a bash session in the `api` container and just type them there.

```
docker-compose run api rake db:create
docker-compose run api rake db:migrate
docker-compose run api rake db:seed
docker-compose run api rspec
docker-compose run api rails g migration AddColumnDockerKnowledgeToBrain
```

Can be run like this:

```
docker-compose run api bash
# then, in bash
rake db:create
rake db:migrate
rake db:seed
rspec
rails g migration AddColumnDockerKnowledgeToBrain
# and when you're done
exit
```

### View status of docker-compose  services

`docker-compose ps`

### Attach to a docker-compose service container

If you want to view the output or interact with a running container, you can attach to it like below. (This is helpful if you use binding.pry to debug the server.)

```
docker-compose ps
# find the name of the container you want to attach to
# below we will attach to georgianbudgetapi_api_1
docker attach georgianbudgetapi_api_1
```

### Convenient Aliases

You'll be typing `docker` and `docker-compose` a lot, so I recommend creating bash aliases for these commands. For example, you can add the following lines to your ~/.bash_profile (or ~/.bashrc):

```
alias do='docker'
alias doco='docker-compose'
```

Then, you can substitute `doco` for `docker-compose` and `do` for `docker` in all of these commands.
