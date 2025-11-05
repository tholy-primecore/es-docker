FROM docker.elastic.co/elasticsearch/elasticsearch:7.12.0

# Create lemmagen folder in config
RUN mkdir -p /usr/share/elasticsearch/config/lemmagen

# Copy lexicon file
COPY cs.lem /usr/share/elasticsearch/config/lemmagen/cs.lem

# Install plugin from local zip
COPY elasticsearch-analysis-lemmagen-7.12.0-plugin.zip /tmp/
RUN elasticsearch-plugin install file:///tmp/elasticsearch-analysis-lemmagen-7.12.0-plugin.zip --batch

# Change ownership (Elasticsearch runs as elasticsearch user)
RUN chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/config/lemmagen
