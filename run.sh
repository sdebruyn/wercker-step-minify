#/bin/bash
set -e

export FAILED=false
export APT_GET_UPDATED=false

# set amount of threads if not set
CORES=`nproc`
echo "$CORES cores detected"
if [ ! -n "$WERCKER_MINIFY_THREADS" ]; then
    export WERCKER_MINIFY_THREADS=$CORES
fi
echo "running with $WERCKER_MINIFY_THREADS threads"

# set base directory to public if not set
DEFAULTDIR="public"
if [ ! -n "$WERCKER_MINIFY_BASEDIR" ]; then
    export WERCKER_MINIFY_BASEDIR=$DEFAULTDIR
fi

# set minify defaults
if [ ! -n "$WERCKER_MINIFY_HTML" ]; then
    export WERCKER_MINIFY_HTML=true
fi
if [ ! -n "$WERCKER_MINIFY_CSS" ]; then
    export WERCKER_MINIFY_CSS=true
fi
if [ ! -n "$WERCKER_MINIFY_JS" ]; then
    export WERCKER_MINIFY_JS=true
fi
if [ ! -n "$WERCKER_MINIFY_HTMLEXT" ]; then
    export WERCKER_MINIFY_HTMLEXT="html"
fi
if [ ! -n "$WERCKER_MINIFY_CSSEXT" ]; then
    export WERCKER_MINIFY_CSSEXT="css"
fi
if [ ! -n "$WERCKER_MINIFY_JSEXT" ]; then
    export WERCKER_MINIFY_JSEXT="js"
fi

# set arguments if not set
DEFAULTARGS="--use-short-doctype --remove-style-link-type-attributes --remove-script-type-attributes --remove-comments --minify-css --minify-js --collapse-whitespace --remove-comments-from-cdata --conservative-collapse --remove-cdatasections-from-cdata"
if [ ! -n "$WERCKER_MINIFY_HTMLARGS" ]; then
    export WERCKER_MINIFY_HTMLARGS="$DEFAULTARGS"
fi

if [ ! -n "$WERCKER_MINIFY_YUIARGS" ]; then
    export WERCKER_MINIFY_YUIARGS=""
fi

command_exists()
{
    hash "$1" 2>/dev/null
}

verifyYUI()
{
    if command_exists yuicompressor; then
        export YUI_COMMAND="yuicompressor"
    else if command_exists yui-compressor; then
        export YUI_COMMAND="yui-compressor"
    else
        verifyJava
        verifyCurl
        curl -L https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar -o yui.jar
        export YUI_COMMAND="java -jar yui.jar"
    fi
}   

minifyHTML()
{
    # minify all the HTML files
    echo "minifying HTML files with extension $WERCKER_MINIFY_HTMLEXT in $WERCKER_MINIFY_BASEDIR with arguments $WERCKER_MINIFY_HTMLARGS"
    
    find ${WERCKER_MINIFY_BASEDIR} -iname *.${WERCKER_MINIFY_HTMLEXT} -print0 | xargs -0 -t -P ${WERCKER_MINIFY_THREADS} -n 1 -I filename html-minifier ${WERCKER_MINIFY_HTMLARGS} -o filename filename
}

minifyCSS()
{
    # minify all the CSS files
    echo "minifying CSS files with extension $WERCKER_MINIFY_CSSEXT in $WERCKER_MINIFY_BASEDIR with arguments $WERCKER_MINIFY_YUIARGS"
    
    find ${WERCKER_MINIFY_BASEDIR} -iname *.${WERCKER_MINIFY_CSSEXT} -print0 | xargs -0 -t -n 1 -P ${WERCKER_MINIFY_THREADS} -I filename ${YUI_COMMAND} ${WERCKER_MINIFY_YUIARGS} -o filename filename
}

minifyJS()
{
    # minify all the JS files
    echo "minifying JS files with extension $WERCKER_MINIFY_JSEXT in $WERCKER_MINIFY_BASEDIR with arguments $WERCKER_MINIFY_YUIARGS"
    
    find ${WERCKER_MINIFY_BASEDIR} -iname *.${WERCKER_MINIFY_JSEXT} -print0 | xargs -0 -t -n 1 -P ${WERCKER_MINIFY_THREADS} -I filename ${YUI_COMMAND} ${WERCKER_MINIFY_YUIARGS} -o filename filename
}

verifyJava()
{
    # check if java is installed
    if ! command_exists java; then
        echo "java not installed, installing..."
        if command_exists apt-get; then
            
            if [ "$APT_GET_UPDATED" = false ] ; then
                apt-get update
                export APT_GET_UPDATED=true
            fi            
                
            apt-get install -y openjdk-7-jre
        else
            yum install -y java-1.7.0-openjdk
        fi
    fi
}

verifyCurl()
{
    # check if curl is installed
    if ! command_exists curl; then
        echo "curl not installed, installing..."
        if command_exists apt-get; then
            
            if [ "$APT_GET_UPDATED" = false ] ; then
                apt-get update
                export APT_GET_UPDATED=true
            fi            
            
            apt-get install -y curl
        else
            yum install -y curl
        fi
    fi
}

verifyNode()
{
    # check if node is installed
    if ! command_exists node; then
    
        verifyCurl
    
        # install node
        echo "node not installed, installing..."
        if command_exists apt-get; then
    		curl -sL https://deb.nodesource.com/setup_0.12 | bash -
            export APT_GET_UPDATED=true
            apt-get install -y nodejs build-essential
        else
            curl -sL https://rpm.nodesource.com/setup | bash -
            yum install -y nodejs gcc-c++ make
        fi
    fi
}

doHTML()
{
    if ! command_exists html-minifier; then
        # install the HTML minifier
        echo "installing html-minifier with npm"
        verifyNode
        npm install html-minifier -g
    fi
    
    # verify HTML minifier installation
    if ! command_exists html-minifier; then
        echo "html-minifier installation failed, not minifying HTML"
        export FAILED=true
    else
        minifyHTML
    fi
}

doCSSJS()
{
    echo "installing yuicompressor..."
    
    if (! command_exists yuicompressor) && (! command_exists yui-compressor); then
        if command_exists apt-get; then
            if [ "$APT_GET_UPDATED" = false ] ; then
                apt-get update
                export APT_GET_UPDATED=true
            fi
            apt-get -y install yui-compressor 2>/dev/null
        fi
        if (! command_exists yuicompressor) && (! command_exists yui-compressor); then
            npm install yuicompressor -g
        fi
        verifyYUI
    fi
    
    if [ "$WERCKER_MINIFY_CSS" != "false" ]; then
        minifyCSS
    fi
    if [ "$WERCKER_MINIFY_JS" != "false" ]; then
        minifyJS
    fi
}

if [ "$WERCKER_MINIFY_HTML" != "false" ]; then
    doHTML
fi

if [ "$WERCKER_MINIFY_CSS" != "false" ] || [ "$WERCKER_MINIFY_JS" != "false" ] ; then
    doCSSJS
fi

if [ "$FAILED" = true ] ; then
    echo "Not all tasks were succesfully completed."
    exit 1
fi
