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

# set amount of threads if not set
CORES=`nproc`
if [ ! -n "$WERCKER_MINIFY_THREADS" ]; then
    export WERCKER_MINIFY_THREADS=$CORES
fi

# install the HTML minifier
npm install html-minifier -g

# minify all the HTML files
find public -iname *.html -print0 | xargs -0 -P ${WERCKER_MINIFY_THREADS} -n 1 -I filename html-minifier --use-short-doctype --remove-style-link-type-attributes --remove-script-type-attributes --remove-comments --minify-css --minify-js --collapse-whitespace -o filename filename
