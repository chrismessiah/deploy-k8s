docker network create elk-net

# ************** ElasticSearch **************
docker run \
  -d \
  --network elk-net \
  --name elasticsearch \
  --network-alias=elasticsearch \
  -p 9200:9200 \
  -p 9300:9300 \
  -e "discovery.type=single-node" \
  elasticsearch:7.0.0

# ************** Kibana **************
docker run \
  -d \
  --network elk-net \
  --name kibana \
  --network-alias=kibana \
  -p 5601:5601 \
  -e ELASTICSEARCH_HOSTS=http://elasticsearch:9200 \
  kibana:7.0.0

curl http://localhost:5601 # access kibana UI

# ************** Logstash **************
mkdir -p /var/lib/logstash/pipeline

# try to add this bellow
# filter {
#   if [name] == "docker_containers" {
#     kv {
#       remove_char_key => "osquery.result.columns"
#       prefix => "container."
#     }
#   }
# }
cat <<EOF > /var/lib/logstash/pipeline/pipeline.conf
input {
	tcp {
		port => 5000
	}
}

output {
	elasticsearch {
		hosts => "elasticsearch:9200"
    index => "logstash-%{+YYYY.MM.dd}"
	}
}
EOF

docker run \
  -d \
  --network elk-net \
  --name logstash \
  --network-alias=logstash \
  -v /var/lib/logstash/pipeline:/usr/share/logstash/pipeline \
  -p 5000:5000 \
  -p 9600:9600 \
  logstash:7.0.0

# ************** OSQuery **************
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
apt-get update
apt-get install osquery

# for interactive SQL queries (exit with ".exit")
osqueryi

cat <<EOF > /etc/osquery/osquery.conf
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
EOF

# to validate the configuration
osqueryctl config-check

# for interacting with the deamon
osqueryd -h

# start osquery deamon
systemctl start osqueryd

# ************** Filebeat **************
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.0.0-amd64.deb
dpkg -i filebeat-7.0.0-amd64.deb

# edit /etc/filebeat/filebeat.yml if config is other than
    # output.elasticsearch:
    #   hosts: ["localhost:9200"]
    #   #index: "filebeat-%{[agent.version]}-%{+yyyy.MM.dd}"
    #   # Optional protocol and basic auth credentials.
    #   #username: "elastic"
    #   #password: "<password>"
    # setup.kibana:
    #   host: "http://localhost:5601"

filebeat modules enable osquery
# Ensure that /etc/filebeat/modules.d/osquery.yml contains the following config
    # - module: osquery
    #   result:
    #     enabled: true
    #     var.paths: ["/var/log/osquery/osqueryd.results.log*"]

filebeat setup
service filebeat start
