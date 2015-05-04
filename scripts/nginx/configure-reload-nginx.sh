#!/bin/bash

function prepare_nginxconf() {
	
	nginx_port=$1
	nodejs_port=$2
	
	ctx logger info "Configuring nginx for nodejs"
	
	temp_dir='/tmp'
	temp_confdir=${temp_dir}/$(ctx execution-id)/nginx

	[ ! -d ${temp_confdir} ] && mkdir ${temp_confdir}

	nginxnode_conf='nginxnode.conf'
	nginxconf_dir='/etc/nginx/conf.d/'

	cat <<CONFIG > ${temp_confdir}/${nginxnode_conf}
	server {
	  listen ${nginx_port};

	  location / {
	    proxy_pass http://127.0.0.1:${nodejs_port};
	    proxy_set_header Host \$host;
	    proxy_set_header X-Real-IP \$remote_addr;
	    proxy_set_header X-Scheme \$scheme;
	    proxy_connect_timeout 1;
	    proxy_send_timeout 30;
	    proxy_read_timeout 30;
	  }
	}
CONFIG

	sudo cp ${temp_confdir}/${nginxnode_conf} ${nginxconf_dir}/${nginxnode_conf}
	
	sudo /etc/init.d/nginx configtest
	config_check=$?
	
	if [ ${config_check} -eq 0 ]; then
		ctx logger info "Nginx configured successfully"
	else
        ctx logger error "Nginx config failed"
		rm -f ${nginxconf_dir}/${nginxnode_conf}
        exit 1;
	fi

}

function get_response_code() {

    port=$1

    set +e

    curl_cmd=$(which curl)
    wget_cmd=$(which wget)

    if [[ ! -z ${curl_cmd} ]]; then
        response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${port})
    elif [[ ! -z ${wget_cmd} ]]; then
        response_code=$(wget --spider -S "http://localhost:${port}" 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -1)
    else
        ctx logger error "Failed to retrieve response code from http://localhost:${port}: Neither 'cURL' nor 'wget' were found on the system"
        exit 1;
    fi

    set -e

    echo ${response_code}

}

function check_reload() {
	
	nginx_port=$1
	
	sudo /etc/init.d/nginx reload
	reload_check=$?
	
	if [ ${reload_check} -eq 0 ]; then
		ctx logger info "Nginx reloaded successfully"
	else
        ctx logger error "Nginx reload failed"
        exit 1
	fi	

    response_code=$(get_response_code ${nginx_port})
    ctx logger info "[GET] http://localhost:${nginx_port} ${response_code}"
    if [ ${response_code} -eq 200 ] ; then
        ctx logger info "Nginx setup was successful"
	else
        ctx logger info "Nginx setup failed"
        exit 1
    fi
	
}

NGINX_PORT=$(ctx source node properties port)
NODECELLAR_PORT=$(ctx target node properties port)

prepare_nginxconf ${NGINX_PORT} ${NODECELLAR_PORT}

check_reload ${NGINX_PORT}