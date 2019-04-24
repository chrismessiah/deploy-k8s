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
cat <<EOF > /var/lib/logstash/pipeline/pipeline.conf
input {
	tcp {
		port => 5000
	}
}

output {
	elasticsearch {
		hosts => "elasticsearch:9200"
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

# ************** Filebeat **************
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.0.0-amd64.deb
dpkg -i filebeat-7.0.0-amd64.deb

# edit /etc/filebeat/filebeat.yml if config is other than
    # output.elasticsearch:
    #   hosts: ["localhost:9200"]
    #   # Optional protocol and basic auth credentials.
    #   #username: "elastic"
    #   #password: "<password>"
    # setup.kibana:
    #   host: "http://localhost:5601"

filebeat modules enable osquery
/etc/filebeat/modules.d/osquery.yml

./filebeat setup
./filebeat -e
