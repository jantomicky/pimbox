#!/bin/bash

SOURCE_FILE="elasticsearch-bin.zip"
SOURCE_URL="https://storage.propelo.cz/$SOURCE_FILE"
EXECUTABLE_PATH="/usr/local/bin/elasticsearch"

echo "Installing custom Elasticsearch binaries (1.0.0 + 1.7.6)…"
echo "Downloading the archive…"
wget -q -P /tmp $SOURCE_URL

if [ ! -f "/tmp/$SOURCE_FILE" ]; then
    echo "ERROR: Failed to download the archive!"
    exit 0;
fi

echo "Unpacking and setting up binaries…"
unzip -q "/tmp/$SOURCE_FILE" -d /opt/
chmod -R 755 /opt/elastic*
chown -R vagrant:vagrant /opt/elastic*

echo "Setting up the executable shell script…"
cat << EOT >> $EXECUTABLE_PATH
#!/bin/bash

if [ -z "\$1" ]; then
    echo "Please specify which version to run (1.0.0 or 1.7.6)."
    exit 0
fi

echo "Stopping all running Elasticsearch instances…"
ps -ef | grep "/opt/elasticsearch" | awk '{print \$2}' | head -n -1 | while read -r pid ; do kill -9 "\$pid"; done

ELASTICSEARCH="/opt/elasticsearch\$1/bin/elasticsearch"

if [ ! -x \$ELASTICSEARCH ]; then
    echo "ERROR: \$ELASTICSEARCH is not executable or does not exist!"
    exit 0
fi

echo "Running Elasticsearch \$1…"

/bin/sh \$ELASTICSEARCH -d
EOT

chmod +x $EXECUTABLE_PATH
echo "Elasticsearch installed."
