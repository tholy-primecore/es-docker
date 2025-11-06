FROM docker.elastic.co/elasticsearch/elasticsearch:8.6.1

# Ensure lemmagen config directory exists (cs.lem is provided via shared volume)
RUN mkdir -p /usr/share/elasticsearch/config/lemmagen

# Install Lemmagen plugin for ES8 from local zip
COPY elasticsearch-analysis-lemmagen-8.6.1-plugin.zip /tmp/
RUN elasticsearch-plugin install file:///tmp/elasticsearch-analysis-lemmagen-8.6.1-plugin.zip --batch


