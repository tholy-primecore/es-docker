# Elasticsearch Docker Setup

Docker Compose setup for running multiple Elasticsearch versions (5, 7, 8, 9) with shared Hunspell dictionaries and Lemmagen plugin support.

## Prerequisites

- Docker and Docker Compose
- `.env` file in the root directory (see Configuration)

## Configuration

Create a `.env` file in the root directory with the following variables:

```bash
# Ports (defaults shown)
ES5_HTTP_PORT=9203
ES5_TRANSPORT_PORT=9303
ES7_HTTP_PORT=9200
ES7_TRANSPORT_PORT=9300
ES8_HTTP_PORT=9201
ES8_TRANSPORT_PORT=9301
ES9_HTTP_PORT=9202
ES9_TRANSPORT_PORT=9302
KIBANA_PORT=5601

# Host paths (adjust to your Laravel project location)
LARAVEL_LOGS_HOST=/path/to/your/project/storage/logs

# Elasticsearch hosts (for Filebeat/Kibana)
ES_HOSTS=http://es7:9200
```

## Running Services

### Start All Services

```bash
cd elasticsearch
docker compose up -d
```

### Start Specific Services

```bash
cd elasticsearch
docker compose up -d es7 kibana filebeat
```

### Data persistence (ES7 / ES8)

ES7 and ES8 store index data in named Docker volumes `es7_data` / `es8_data` (mounted at `/usr/share/elasticsearch/data`).

| Action | Indexes kept? |
|--------|----------------|
| `docker compose stop` / `start` | Yes |
| `docker compose up -d es7` / `es8` (recreate container) | Yes |
| `docker compose down` | Yes |
| `docker compose down -v` | **No** — deletes volumes |
| `docker volume rm elasticsearch_es7_data` / `elasticsearch_es8_data` | **No** |

If indexes disappear after a restart, the container was likely recreated **without** a data volume (older compose files) or volumes were removed with `-v`.

### Stop Services

```bash
cd elasticsearch
docker compose stop
```

### Checking if Elasticsearch is running

```bash
docker ps
```

If the container (e.g. `es5`) is running, test the HTTP API:

```bash
curl -s http://localhost:9203
```

Use port `9200` for ES7, `9201` for ES8, `9202` for ES9.

If `curl` returns nothing or hangs, the container may be in a restart loop. Check why it exits:

```bash
docker logs es5 --tail 80
```

## Switching Between Elasticsearch Versions

Use the `es-switch.sh` script to easily manage different ES versions:

```bash
cd elasticsearch
./es-switch.sh [5|7|8|9] [start|stop|restart]
```

### Examples

Start ES5:
```bash
./es-switch.sh 5 start
```

Start ES7:
```bash
./es-switch.sh 7 start
```

Stop ES8:
```bash
./es-switch.sh 8 stop
```

Restart ES9:
```bash
./es-switch.sh 9 restart
```
Switching automatically stops the other running container

## Ports

- **ES5**: HTTP `9203`, Transport `9303`
- **ES7**: HTTP `9200`, Transport `9300`
- **ES8**: HTTP `9201`, Transport `9301`
- **ES9**: HTTP `9202`, Transport `9302`
- **Kibana**: `5601`

## Shared Resources

All ES versions share:
- **Hunspell dictionaries**: `./shared/hunspell/`
- **Lemmagen lexicon**: `./shared/lemmagen/cs.lem`
- **Filebeat config**: `./shared/filebeat/filebeat.yml`

## Version-Specific Notes

- **ES5**: Standard image (5.5.1), shared Hunspell and Lemmagen paths only. On Linux, if the container exits on bootstrap check, run `sysctl -w vm.max_map_count=262144` on the host.
- **ES7**: Includes Lemmagen plugin (7.12.0)
- **ES8**: Includes Lemmagen plugin (8.6.1), security disabled by default
- **ES9**: Standard image, no plugins installed

## Kibana and Filebeat

- **Kibana** (7.12.0) connects to ES7 by default. Change `ES_HOSTS` in `.env` to point to a different version.
- **Filebeat** reads Laravel logs from the path specified in `LARAVEL_LOGS_HOST` and sends to ES7 by default.

## Building Custom Images

Rebuild ES images after changes:

```bash
cd elasticsearch
docker compose build es5
docker compose build es7
docker compose build es8
```

**ES5 on ARM Mac:** To remove the platform warning (and use the amd64 image), run this one-time rebuild:

```bash
cd elasticsearch
docker compose stop es5
docker rmi elasticsearch-es5:linux-amd64
docker compose build --no-cache es5
./es-switch.sh 5 start
```

If you skip this, the container still runs but Docker will show a platform mismatch warning each time.
## Alias for easy switching (add to ~/.zshrc)
alias es5="/path/to/the/project/elasticsearch/es-switch.sh 5"
alias es7="/path/to/the/project/elasticsearch/es-switch.sh 7"
alias es8="/path/to/the/project/elasticsearch/es-switch.sh 8"
alias es9="/path/to/the/project/elasticsearch/es-switch.sh 9"

### Usage in any folder
```bash
es5 start
es7 start
es8 stop
es9 restart
```


## Iris-v2 usage

Change the .env values for specific es version

es5:
```
ELASTIC_SEARCH_PORT=9203
```

es7:
```
ELASTIC_SEARCH_HOST=localhost
ELASTIC_SEARCH_PORT=9200
ELASTIC_SEARCH_INDEX=iris_v2
```

es8:
```
ELASTIC_SEARCH_PORT=9201
```

es9:
```
ELASTIC_SEARCH_PORT=9202
```
