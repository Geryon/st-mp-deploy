#!/bin/bash
###############################################################################
##
## Deployment script for Stelligent Candidate Mini-Project
##
##   This script will install git, ansible, and required python modules.  It
##   will also properly set up the environment and run the ansible playbook
##   to provision and deploy the environment and web site. 
##   View the man page '--man' for additional details.
##
##   Nicholas DeClario <nick@declario.com>
##   February 2015
##
###############################################################################

##
## Set some global variables
##
declare ARGS_REQ=0  ## Are arguments required?
declare HOSTNAME="st-mp"
declare MAIL_TO="nick@declario.com"
declare PROV_ONLY=0
declare SECURE_URL="https://s3-us-west-1.amazonaws.com/st-mp.provisioning/secure_20150213.tar.gz"

###############################################################################
##
## help( )
## 
##    Display the basic help text
##
###############################################################################
help( ) {
        cat <<EOF
Usage:
    $0 [options]

    Options:
       --help,?         Display the basic help menu
       --hostname       The hostname of the EC2 Instance to provision
       --mail_to        Address to mail completion message to
       --man,m          Display the detailed man page
       --provision_only Just run the ansible job
EOF

    exit 1
} 

###############################################################################
##
## man( )
##
##      Display the detailed man page
##
###############################################################################
man( ) {
        cat <<EOF | nroff -man
.TH st-mp-deploy.sh "$(date)" 
.SH NAME
st-mp-deply.sh \- Deployment script for Stelligent Candidate Mini-Project
.SH SYNOPSIS
.B st-mp-deply.sh
[ --hostname <HOSTNAME> --mail_to <ADDRESS> --provision_only ]
.SH DESCRIPTION
.I st-mp-deply.sh
This script will install git, ansible, and required python modules.  It will also properly set up the environment and run the ansible playbook to provision and deploy the environment and web site.
.SH OPTIONS
.TP
.BR --hostname
This EC2 instance contains a tag called 'Name'.  This can be populated at the time of provisioning and provides a unique way to easily identify an instance.  Additionally, if DNS was configured this could provide the hostname portion of the FQDN; therefore, this name should abide by typical hostname syntax.
.TP
.BR --mail_to
Upon completion of the provisioning of the instance and deployment of the website a notification e-mail is sent out.  This e-mail contains the EC2 instance ID and the external DNS name.
.TP
.BR --provision_only
This skips configuration of the local environment and runs only the ansible scripts.  See the 'DETAILS' section below for additional information.
.SH DETAILS
.TP
If the '--provision_only' option is not specified the environment for pulling down the code and running the Ansible playbooks will be configured.  This will require sudo root access to the system and a prompt will be provided for the sudo password.  It is *NOT* recommended to run this script as root.
.TP
To build the environment 'git' and 'python-pip' will be installed via the apt package management system.  Once installed, pip is utilized to install 'python-boto', 'pyYaml' and 'jinja2'.  These are all required for proper operation of Ansible.  The Ansible GIT repository will be cloned.  Branch 'release1.8.2' is used.  This is the end of the environment configuration.  
.TP
With these in place the st-mp playbooks are fetched from github.  A clone of 'https://github.com/Geryon/st-mp' is performed.  This will save everything in '~/st-mp'.  After this is completed there is a subdirectory that contains all sensitive data, AWS keys, public keys (some private keys specifically for this project) and user configurations, will be downloaded from S3 and uncompressed in to '~/st-mp/secure'.  Take note of that directory as it will be required to be passed to the Ansible playbook command via the '--extra' option.  Everything beyond here is performed regardless of the '--provision_only' option.
.TP
The system is in place at this point.  What is left is to set a few variables.  Ansible provides a script to configure the environment when running Ansible from GIT, this is '~/ansible/hacking/env-setup', which is sourced in to the current shell.  Additionally, we disable strict host key checking in OpenSSL for Ansible by setting 'ANSIBLE_HOST_KEY_CHECKING=False'.  At this point the ansible playbook command can be ran.  This is an example of that command:
.TP
.BR
ansible-playbook -i localhost, st-mp/playbooks/stelligent-mp.yml -e 'secure_dir="/home/nick/st-mp/secure" hostname="st-mp-01" mail_to="nick@declario.com"' -t provision,deploy
.SH "SEE ALSO"
man(1)
.SH "BUGS"
.I st-mp-deploy.sh
is a work in progress.  Please report bugs.
.SH "AUTHOR"
.I Nicholas DeClario
<nick@declario.com>
EOF
    exit 1;
}

###############################################################################
## End of shell function definitions
###############################################################################

##
##  We are going to read in our basic set of options and parse everything 
##  out.  Setting NOARGS to 1 at the top of this script will tell getOpts 
##  to call 'help' if no arguments are supplied on the command line.
##

## 
## If we require arguments and have none, show the help
##
[ $# -lt $ARGS_REQ ] && help;

##
## Parse through our command line arguments here
##
while [ $# -gt 0 ]
do
    arg=$1
    shift

    case $arg in
        --hostname)
            HOSTNAME="$1"
            shift
            ;;
        --mail_to)
            MAIL_TO="$1"
            shift
            ;;
        --man)
            man
            break
            ;;
        --provision_only)
            PROV_ONLY=1
            ;;
        *)
            help
            break
            ;;
    esac
done

cd ~

if [[ ${PROV_ONLY} -ne 1 ]]; then
    echo "You will be promted for the root password to install git and python modules"
    set -e
    sudo apt-get update
    sudo apt-get -y install git python-pip
    sudo pip install boto pyyaml jinja2
    if [ -d ansible ]; then
        pushd ansible   
        git pull
        popd
    else
        git clone -b release1.8.2 https://github.com/ansible/ansible
    fi
    [ -d ansible ] || \
    {
        echo "Error: The ansible repository did not clone from github correctly"
        exit 1
    }
    pushd ansible && git submodule update --init --recursive && popd
    if [ -d st-mp ]; then
        pushd st-mp
        git pull
        popd
    else
        git clone https://github.com/Geryon/st-mp
    fi
    [ -d st-mp ] || \
    {
        echo "Error: The st-mp repository did not clone from github correctly"
        exit 1
    }
    wget -q "${SECURE_URL}" -O - | tar zxf - -C st-mp/
fi

export ANSIBLE_HOST_KEY_CHECKING=False
. ~/ansible/hacking/env-setup

ansible-playbook -i localhost, st-mp/playbooks/stelligent-mp.yml -e 'secure_dir="/home/nick/st-mp/secure" hostname="'"${HOSTNAME}"'" mail_to="'"${MAIL_TO}"'"' -t provision,deploy
