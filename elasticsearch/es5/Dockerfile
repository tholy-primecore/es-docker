FROM --platform=linux/amd64 elasticsearch:5.5.1

RUN elasticsearch-plugin install https://github.com/vhyza/elasticsearch-analysis-lemmagen/releases/download/v5.5.1/elasticsearch-analysis-lemmagen-5.5.1-plugin.zip

RUN mkdir -p /usr/share/elasticsearch/config/hunspell
RUN mkdir -p /usr/share/elasticsearch/config/lemmagen

ADD https://github.com/elastic/hunspell/raw/master/zips/cs.zip /usr/share/elasticsearch/config/hunspell/
ADD https://github.com/elastic/hunspell/raw/master/zips/sk.zip /usr/share/elasticsearch/config/hunspell/

WORKDIR /usr/share/elasticsearch/config/hunspell

RUN unzip cs.zip -d cs_CZ
RUN unzip sk.zip

RUN mv hunspell-sk-20110228 sk_SK
