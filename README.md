# Elasticsearch Docker Setup

Docker Compose setup for running multiple Elasticsearch versions (7, 8, 9) with shared Hunspell dictionaries and Lemmagen plugin support.

## Prerequisites

- Docker and Docker Compose
- `.env` file in the root directory (see Configuration)

## Configuration

Create a `.env` file in the root directory with the following variables:

```bash
# Ports (defaults shown)
ELASTIC_SEARCH_PORT=9201
ELASTIC_SEARCH_INDEX=iris_v2
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

### Stop Services

```bash
cd elasticsearch
docker compose stop
```

## Switching Between Elasticsearch Versions

Use the `es-switch.sh` script to easily manage different ES versions:

```bash
cd elasticsearch
./es-switch.sh [7|8|9] [start|stop|restart]
```

### Examples

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
docker compose build es7
docker compose build es8
```
## Alias for easy switching (add to ~/.zshrc)
alias es7="~/docker/elasticsearch/es-switch.sh 7"
alias es8="~/docker/elasticsearch/es-switch.sh 8"
alias es9="~/docker/elasticsearch/es-switch.sh 9"

### Usage in any folder
```bash
es7 start
es8 stop
es9 restart
```


## Iris-v2 usage

Change the .env values for specific es version

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
