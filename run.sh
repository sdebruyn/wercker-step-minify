#/bin/bash
set -e

# http://stackoverflow.com/a/8574392/1592358
contains_element ()
{
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

# is true if the script should run
check_branches ()
{
    # check if the branches match and abort the script if needed
    if [ -n "$WERCKER_MINIFY_IGNORE_BRANCHES" ]; then
        arr=($WERCKER_MINIFY_IGNORE_BRANCHES)
        if contains_element "$WERCKER_GIT_BRANCH" "${arr[@]}"; then
            echo "We are not running on branch ${WERCKER_GIT_BRANCH}"
            return 1
        fi
    elif [ -n "$WERCKER_MINIFY_ONLY_ON_BRANCHES" ]; then
        arr=($WERCKER_MINIFY_ONLY_ON_BRANCHES)
        if ! contains_element "$WERCKER_GIT_BRANCH" "${arr[@]}"; then
            echo "We are not running on branch ${WERCKER_GIT_BRANCH}"
            return 1
        fi
    else
        return 0
    fi
}

FAILED=false
APT_GET_UPDATED=false

set_variables()
{
    # set amount of threads if not set
    CORES=$(nproc)
    echo "$CORES cores detected"
    if [ ! -n "$WERCKER_MINIFY_THREADS" ]; then
        WERCKER_MINIFY_THREADS=$CORES
    fi
    echo "running with $WERCKER_MINIFY_THREADS threads"
    
    # set base directory to public if not set
    DEFAULTDIR="public"
    if [ ! -n "$WERCKER_MINIFY_BASE_DIR" ]; then
        WERCKER_MINIFY_BASE_DIR=$DEFAULTDIR
    fi
    
    # set minify defaults
    if [ ! -n "$WERCKER_MINIFY_HTML" ]; then
        WERCKER_MINIFY_HTML=true
    fi
    if [ ! -n "$WERCKER_MINIFY_CSS" ]; then
        WERCKER_MINIFY_CSS=true
    fi
    if [ ! -n "$WERCKER_MINIFY_JS" ]; then
        WERCKER_MINIFY_JS=true
    fi
    if [ ! -n "$WERCKER_MINIFY_HTML_EXT" ]; then
        WERCKER_MINIFY_HTML_EXT="html"
    fi
    if [ ! -n "$WERCKER_MINIFY_CSS_EXT" ]; then
        WERCKER_MINIFY_CSS_EXT="css"
    fi
    if [ ! -n "$WERCKER_MINIFY_JS_EXT" ]; then
        WERCKER_MINIFY_JS_EXT="js"
    fi
}

command_exists()
{
    echo "checking if $1 is installed..."
    hash "$1" 2>/dev/null
}

verify_YUI()
{
    if command_exists yuicompressor; then
        YUI_COMMAND="yuicompressor"
    elif command_exists yui-compressor; then
        YUI_COMMAND="yui-compressor"
    else
        echo "installing yuicompressor with java..."
        verify_java
        verify_curl
        echo "downloading yuicompressor with curl..."
        curl -L https://github.com/yui/yuicompressor/releases/download/v2.4.8/yuicompressor-2.4.8.jar -o yui.jar
        YUI_COMMAND="java -jar yui.jar"
    fi
}

minify_HTML()
{
    # minify all the HTML files
    echo "minifying HTML files with extension $WERCKER_MINIFY_HTML_EXT in $WERCKER_MINIFY_BASE_DIR with arguments $WERCKER_MINIFY_HTML_ARGS"
    
    find ${WERCKER_MINIFY_BASE_DIR} -iname "*.${WERCKER_MINIFY_HTML_EXT}" -print0 | xargs -0 -t -P "${WERCKER_MINIFY_THREADS}" -n 1 -I filename html-minifier "${WERCKER_MINIFY_HTML_ARGS}" -o filename filename
}

minify_CSS()
{
    # minify all the CSS files
    echo "minifying CSS files with extension $WERCKER_MINIFY_CSS_EXT in $WERCKER_MINIFY_BASE_DIR with arguments $WERCKER_MINIFY_YUI_ARGS and command $YUI_COMMAND"
    
    find ${WERCKER_MINIFY_BASE_DIR} -iname "*.${WERCKER_MINIFY_CSS_EXT}" -print0 | xargs -0 -t -n 1 -P "${WERCKER_MINIFY_THREADS}" -I filename "${YUI_COMMAND}" "${WERCKER_MINIFY_YUI_ARGS}" -o filename filename
}

minify_JS()
{
    # minify all the JS files
    echo "minifying JS files with extension $WERCKER_MINIFY_JS_EXT in $WERCKER_MINIFY_BASE_DIR with arguments $WERCKER_MINIFY_YUI_ARGS and command $YUI_COMMAND"
    
    find ${WERCKER_MINIFY_BASE_DIR} -iname "*.${WERCKER_MINIFY_JS_EXT}" -print0 | xargs -0 -t -n 1 -P "${WERCKER_MINIFY_THREADS}" -I filename "${YUI_COMMAND}" "${WERCKER_MINIFY_YUI_ARGS}" -o filename filename
}

verify_java()
{
    # check if java is installed
    if ! command_exists java; then
        echo "java not installed, installing..."
        if command_exists apt-get; then
            
            if [ "$APT_GET_UPDATED" = false ] ; then
                apt-get update
                APT_GET_UPDATED=true
            fi            
                
            apt-get install -y openjdk-7-jre
        else
            yum install -y java-1.7.0-openjdk
        fi
    fi
}

verify_curl()
{
    # check if curl is installed
    if ! command_exists curl; then
        echo "curl not installed, installing..."
        if command_exists apt-get; then
            
            if [ "$APT_GET_UPDATED" = false ] ; then
                apt-get update
                APT_GET_UPDATED=true
            fi            
            
            apt-get install -y curl
        else
            yum install -y curl
        fi
    fi
}

verify_node()
{
    # check if node is installed
    if ! command_exists node; then
    
        verify_curl
    
        # install node
        echo "node not installed, installing..."
        if command_exists apt-get; then
    		curl -sL https://deb.nodesource.com/setup_0.12 | bash -
            APT_GET_UPDATED=true
            apt-get install -y nodejs build-essential
        else
            curl -sL https://rpm.nodesource.com/setup | bash -
            yum install -y nodejs gcc-c++ make
        fi
    fi
}

do_HTML()
{
    if ! command_exists html-minifier; then
        # install the HTML minifier
        echo "installing html-minifier with npm"
        verify_node
        npm install html-minifier -g
    fi
    
    # verify HTML minifier installation
    if ! command_exists html-minifier; then
        echo "html-minifier installation failed, not minifying HTML"
        FAILED=true
    else
        minify_HTML
    fi
}

do_CSS_JS()
{
    echo "installing yuicompressor..."
    
    if (! command_exists yuicompressor) && (! command_exists yui-compressor); then
        if command_exists apt-get; then
            if [ "$APT_GET_UPDATED" = false ] ; then
                apt-get update
                APT_GET_UPDATED=true
            fi
            apt-get -y install yui-compressor 2>/dev/null
        fi
        if (! command_exists yuicompressor) && (! command_exists yui-compressor); then
            echo "installing yuicompressor with npm..."
            npm install yuicompressor -g
        fi
    fi
    
    verify_YUI
    
    if [ "$WERCKER_MINIFY_CSS" != "false" ]; then
        minify_CSS
    fi
    if [ "$WERCKER_MINIFY_JS" != "false" ]; then
        minify_JS
    fi
}

if check_branches; then
    set_variables
    
    if [ "$WERCKER_MINIFY_HTML" != "false" ]; then
        do_HTML
    fi
    
    if [ "$WERCKER_MINIFY_CSS" != "false" ] || [ "$WERCKER_MINIFY_JS" != "false" ] ; then
        do_CSS_JS
    fi
fi

if [ "$FAILED" = true ] ; then
    echo "Not all tasks were succesfully completed."
    exit 1
fi
