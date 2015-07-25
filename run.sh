#/bin/bash
set -e

SUCCESS=true

# set amount of threads if not set
CORES=`nproc`
echo $CORES cores detected
if [ ! -n "$WERCKER_MINIFY_THREADS" ]; then
    export WERCKER_MINIFY_THREADS=$CORES
fi
echo running with $WERCKER_MINIFY_THREADS threads

# set base directory to public if not set
DEFAULTDIR="public"
if [ ! -n "$WERCKER_MINIFY_BASEDIR" ]; then
    export WERCKER_MINIFY_BASEDIR=$DEFAULTDIR
fi

# set arguments if not set
DEFAULTARGS="--use-short-doctype --remove-style-link-type-attributes --remove-script-type-attributes --remove-comments --minify-css --minify-js --collapse-whitespace --remove-comments-from-cdata --conservative-collapse --remove-cdatasections-from-cdata"
if [ ! -n "$WERCKER_MINIFY_HTMLARGS" ]; then
    export WERCKER_MINIFY_HTMLARGS="$DEFAULTARGS"
fi

if [ ! -n "$WERCKER_MINIFY_YUIARGS" ]; then
    export WERCKER_MINIFY_YUIARGS=""
fi

# check if node is installed
if [ "$(which node)" == "" ]; then

    # check if curl is installed
    if [ "$(which curl)" == "" ]; then
        echo curl not installed, installing...
        if [ "$(which apt-get)" != "" ]; then
            apt-get update
            apt-get install -y curl
        else
            yum install -y curl
        fi
    fi

    # install node
    echo node not installed, installing...
    if [ "$(which apt-get)" != "" ]; then
		curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -
        apt-get install -y npm nodejs build-essential
    else
        curl --silent --location https://rpm.nodesource.com/setup | bash -
        yum install -y nodejs npm gcc-c++ make
    fi
fi

# install the HTML minifier
echo installing html-minifier with npm
npm install html-minifier -g

# verify HTML minifier installation
if [ "$(which html-minifier)" == "" ]; then
    echo html-minifier installation failed, not minifying HTML
    SUCCESS=false
else
    # minify all the HTML files
    echo "minifying HTML files in $WERCKER_MINIFY_BASEDIR with arguments $WERCKER_MINIFY_HTMLARGS"
    
    find ${WERCKER_MINIFY_BASEDIR} -iname *.html -print0 | xargs -0 -t -P ${WERCKER_MINIFY_THREADS} -n 1 -I filename html-minifier ${WERCKER_MINIFY_HTMLARGS} -o filename filename
fi

# check if java is installed
if [ "$(which java)" == "" ]; then
    echo java not installed, installing...
    if [ "$(which apt-get)" != "" ]; then
        apt-get update
        apt-get install -y openjdk-7-jre
    else
        yum install -y java-1.7.0-openjdk
    fi
fi

# install yui-compressor
echo installing yui-compressor with npm
npm install yui-compressor -g

# verify yui-compressor installation
if [ "$(which yui-compressor)" == "" ]; then
    echo yui-compressor installation failed, not minifying CSS and JS
    SUCCESS=false
else
    # minify all the CSS and JS files
    echo "minifying CSS and JS files in $WERCKER_MINIFY_BASEDIR with arguments $WERCKER_MINIFY_YUIARGS"
    
    find ${WERCKER_MINIFY_BASEDIR} -iname *.css -print0 -or -iname *.js -print0 | xargs -0 -t -n 1 -P ${WERCKER_MINIFY_THREADS} -I filename yui-compressor ${WERCKER_MINIFY_YUIARGS} -o filename filename
fi

if $SUCCESS ; then exit 1 ; fi
