#!/usr/bin/env bash

######################################################################
# This script installs required dependencies for Torch7
# It was copied from original install-deps.sh so might need updating
# every now and then
# Specially tailored for Ubuntu 14.04 on IVC Cluster at ETHZ
######################################################################
##set -e
##{

INSTALL_DIR="$1"
echo "SCRIPT_OUT:Installing dependencies in ${INSTALL_DIR}"
####################################################################
# Local installer
####################################################################
function local_install {
  apt-get download "$1"  
  dpkg -i "$1".deb --force-not-root --root="$INSTALL_DIR"
}

install_openblas() {
    # Get and build OpenBlas (Torch is much better with a decent Blas)
    git clone https://github.com/xianyi/OpenBLAS.git
    cd OpenBLAS
    # openMP is available by module load
    make NO_AFFINITY=1 USE_OPENMP=1
    RET=$?;
    if [ $RET -ne 0 ]; then
        echo "SCRIPT_OUT:Error. OpenBLAS could not be compiled";
        exit $RET;
    fi
    make PREFIX="$INSTALL_DIR" install 
    RET=$?;
    if [ $RET -ne 0 ]; then
        echo "SCRIPT_OUT:Error. OpenBLAS could not be installed";
        exit $RET;
    else
        echo "SCRIPT_OUT:OpenBLAS installed"
    fi
}

# Based on Platform:
if [[ "$(uname)" == 'Linux' ]]; then

    if [[ -r /etc/os-release ]]; then
        # this will get the required information without dirtying any env state
        DIST_VERS="$( ( . /etc/os-release &>/dev/null
                        echo "$ID $VERSION_ID") )"
        DISTRO="${DIST_VERS%% *}" # get our distro name
        VERSION="${DIST_VERS##* }" # get our version number
    elif [[ -r /etc/lsb-release ]]; then
        DIST_VERS="$( ( . /etc/lsb-release &>/dev/null
                        echo "${DISTRIB_ID,,} $DISTRIB_RELEASE") )"
        DISTRO="${DIST_VERS%% *}" # get our distro name
        VERSION="${DIST_VERS##* }" # get our version number
    else # well, I'm out of ideas for now
        echo 'SCRIPT_OUT:==> Failed to determine distro and version.'
        exit 1
    fi

    # Detect Ubuntu
    if [[ "$DISTRO" = "ubuntu" ]]; then
        export DEBIAN_FRONTEND=noninteractive
        distribution="ubuntu"
        ubuntu_major_version="${VERSION%%.*}"
    else
        echo '==> Only Ubuntu supported.'
        exit 1
    fi

    # Install dependencies for Torch:
    if [[ $distribution == 'ubuntu' ]]; then
        # python-software-properties is installed on euryale
        # sudo apt-get install -y python-software-properties
        echo "SCRIPT_OUT:==> Found Ubuntu version ${ubuntu_major_version}.xx"
        if [[ $ubuntu_major_version == '14' ]]; then # 14.xx
            local_install software-properties-common
            # not trying ipython for now
            #sudo -E add-apt-repository -y ppa:jtaylor/ipython
        else
          echo "SCRIPT_OUT:Ubuntu version not 14, check script"
        fi

        # Hope we don't need all this, installing libpng16 etc is a big headache :(

        #local_install build-essential gcc g++ curl \
        #    cmake libreadline-dev git-core libqt4-dev libjpeg-dev \
        #    libpng-dev ncurses-dev imagemagick libzmq3-dev gfortran \
        #    unzip gnuplot gnuplot-x11 ipython

        # module load has set gcc version to 4.9
        #if [[ $ubuntu_major_version -lt '15' ]]; then
            # linqt4-dev is installed
            #sudo apt-get install libqt4-core libqt4-gui
        #fi

	#OpenBLAS already present at /usr/lib/libopenblas.so
        #install_openblas || true

else
    # Unsupported
    echo '==> platform not supported, only Linux supported, aborting'
    exit 1
fi

ipython_exists=$(command -v ipython) || true
if [[ $ipython_exists ]]; then {
    ipython_version=$(ipython --version|cut -f1 -d'.')
    if [[ $ipython_version -lt 2 ]]; then {
        echo 'SCRIPT_OUT:WARNING: Your ipython version is too old.  Type "ipython --version" to see this.  Should be at least version 2'
    } fi
} fi

# Done.
echo "SCRIPT_OUT:==> Torch7's dependencies have been installed"

##}
