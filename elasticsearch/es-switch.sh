#!/bin/zsh

VERSION=$1
ACTION=${2:-start}

if [[ -z "$VERSION" ]]; then
  echo "Usage: es-switch.sh [5|7|8|9] start|stop|restart"
  exit 1
fi

# Map version to service name in unified docker-compose.yml
case $VERSION in
  5) SERVICE="es5" ;;
  7) SERVICE="es7" ;;
  8) SERVICE="es8" ;;
  9) SERVICE="es9" ;;
  *) echo "Invalid version: $VERSION. Use 5, 7, 8, or 9."; exit 1 ;;
esac

# cd to the directory of this script (path-agnostic)
SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
cd "$SCRIPT_DIR" || exit

case $ACTION in
  start)
    docker compose up -d --remove-orphans $SERVICE
    ;;
  stop)
    docker compose stop $SERVICE
    ;;
  restart)
    docker compose restart $SERVICE
    ;;
  *)
    echo "Invalid action: $ACTION. Use start, stop, restart."
    exit 1
    ;;
esac
