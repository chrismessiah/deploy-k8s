
# Create Docker network

```sh
docker network create elk-net
```

# ElasticSearch

```sh
docker run \
  -d \
  --network elk-net \
  --name elasticsearch \
  --network-alias=elasticsearch \
  -p 9200:9200 \
  -p 9300:9300 \
  -e "discovery.type=single-node" \
  elasticsearch:7.0.0
```

# Kibana

```sh
docker run \
  -d \
  --network elk-net \
  --name kibana \
  --network-alias=kibana \
  -p 5601:5601 \
  -e ELASTICSEARCH_HOSTS=http://elasticsearch:9200 \
  kibana:7.0.0

curl http://localhost:5601 # access kibana UI
```

# Logstash
https://www.elastic.co/guide/en/logstash/current/advanced-pipeline.html

```sh
mkdir -p /var/lib/logstash/pipeline
touch /var/lib/logstash/pipeline/pipeline.conf
```

```yaml
# /var/lib/logstash/pipeline/pipeline.conf
input {
  tcp {
    port => 5000
  }
}

output {
  elasticsearch {
    hosts => "elasticsearch:9200"
    index => "foo-%{+YYYY.MM.dd}"
  }
}
```

```sh
docker run \
  -d \
  --network elk-net \
  --name logstash \
  --network-alias=logstash \
  -v /var/lib/logstash/pipeline:/usr/share/logstash/pipeline \
  -p 5000:5000 \
  -p 9600:9600 \
  logstash:7.0.0
```

```sh
# Test config
logstash -f first-pipeline.conf --config.test_and_exit

# hot reload when pipeline-file is edited
logstash -f first-pipeline.conf --config.reload.automatic
```

# Curator

```
apt install python-pip
pip install elasticsearch-curator

curator --help
curator action.yaml

curator_cli --help
```

# OSQuery
```sh
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
apt-get update
apt-get install osquery

mkdir -p /etc/osquery
touch /etc/osquery/osquery.conf
```

Edit `/etc/osquery/osquery.conf` and add the following
```json
{
  "options": {
    "host_identifier": "hostname",
    "schedule_splay_percent": 10,
    "enable_monitor": "true"
  },
  "schedule": {
    "docker_containers": {
      "query": "SELECT * FROM docker_containers;",
      "interval": 10
    },
    "docker_images": {
      "query": "SELECT * FROM docker_images;",
      "interval": 20
    }
  },
  "packs": {
    "osquery-monitoring": "/usr/share/osquery/packs/osquery-monitoring.conf",
     "incident-response": "/usr/share/osquery/packs/incident-response.conf",
     "it-compliance": "/usr/share/osquery/packs/it-compliance.conf",
     "vuln-management": "/usr/share/osquery/packs/vuln-management.conf"
  }
}
```

```sh
# for interactive SQL queries (exit with ".exit")
osqueryi

# to validate the configuration
osqueryctl config-check

# for interacting with the deamon
osqueryd -h

# start osquery deamon
systemctl start osqueryd
```

# Filebeat

```sh
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.0.0-amd64.deb
dpkg -i filebeat-7.0.0-amd64.deb

mkdir -p /etc/filebeat
touch /etc/filebeat/filebeat.yml
```

edit `/etc/filebeat/filebeat.yml` to set the following configuration

```yaml
output.elasticsearch:
  hosts: ["localhost:9200"]
  index: "bar-%{[agent.version]}-%{+yyyy.MM.dd}"
setup:
  ilm.enabled: false # ILM defaults to true in filebeat 7 which overrides index 
  template:
    name: bar
    pattern: bar-*
    overwrite: true
```
or

```yaml
filebeat.inputs:
- type: log
  paths:
    - /path/to/file/logstash-tutorial.lo
output.logstash:
  hosts: ["localhost:5044"]
```

Then

```sh
filebeat modules enable osquery
```

Ensure that /etc/filebeat/modules.d/osquery.yml contains the following config

``` yaml
- module: osquery
  result:
    enabled: true
    var.paths: ["/var/log/osquery/osqueryd.results.log*"]
```

```sh
filebeat setup
service filebeat start
```
