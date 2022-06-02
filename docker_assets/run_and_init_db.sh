postgres -c 'max_connections=1000' &

export POSTGRES_HOST=localhost
export POSTGRES_DB=neon-db
export POSTGRES_USER=neon-proxy
export POSTGRES_PASSWORD=neon-proxy-pass
export PGPASSWORD=${POSTGRES_PASSWORD}

#psql --username=neon-proxy --dbname=neon-db --host=postgres --password=neon-proxy-pass

psql -h ${POSTGRES_HOST} --dbname ${POSTGRES_DB}  --username ${POSTGRES_USER} -a -f /docker_assets/neon_scheme.sql
psql -h ${POSTGRES_HOST} --dbname ${POSTGRES_DB}  --username ${POSTGRES_USER} --command "\\dt+ public.*"
psql -h ${POSTGRES_HOST} --dbname ${POSTGRES_DB}  --username ${POSTGRES_USER} --command "\\d+ public.*"
