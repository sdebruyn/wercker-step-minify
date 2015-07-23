#/bin/bash
set -e

# check if node is installed
if [ "$(which node)" == "" ]; then

    # check if curl is installed
    if [ "$(which curl)" == "" ]; then
        if [ "$(which apt-get)" != "" ]; then
            apt-get update
            apt-get install -y curl
        else
            yum install -y curl
        fi
    fi

    # install node
    if [ "$(which apt-get)" != "" ]; then
		curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
        apt-get install -y npm nodejs build-essential
    else
        curl --silent --location https://rpm.nodesource.com/setup | bash -
        yum install -y nodejs npm gcc-c++ make
    fi
fi

# install the HTML minifier
npm install html-minifier -g
