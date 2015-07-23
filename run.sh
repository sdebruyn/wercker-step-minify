#/bin/bash
set -e

# check if node is installed
if [ "$(which node)" == "" ]; then
    if [ "$(which apt-get)" != "" ]; then
		apt-get update
        apt-get install -y npm nodejs build-essential
    else
        yum install -y nodejs npm gcc-c++ make
    fi
fi

# install the HTML minifier
npm install html-minifier -g
