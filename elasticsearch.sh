#!/bin/bash -e

catalog/search/elasticsearch7_server_hostname: http://localhost
catalog/search/elasticsearch7_server_port: 9200
catalog/search/elasticsearch7_enable_auth: 0
del: catalog/search/elasticsearch7_username
del: catalog/search/elasticsearch7_password
