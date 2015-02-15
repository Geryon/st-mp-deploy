# st-mp-deploy

st-mp-deply.sh  This  script  will  install  git, ansible, and 
required python modules.  It will also properly set up the envi-
ronment  and  run the  ansible  playbook  to provision and depl-
oy the environment and web site.

## Synopsis

```
st-mp-deply.sh [ --hostname  <HOSTNAME>  --mail_to  <ADDRESS>  --provi‐ sion_only ]
```

## Options
**--hostname**
<ul>
This EC2 instance contains a tag called  'Name'.   This  can  be
populated  at the time of provisioning and provides a unique way
to easily identify an instance.  Additionally, if DNS  was  con‐
figured  this  could  provide  the hostname portion of the FQDN;
therefore, this name should abide by typical hostname syntax.
</ul>

**--mail_to**
<ul>
Upon completion of the provisioning of the instance and  deploy‐
ment  of the website a notification e-mail is sent out.  This e-
mail contains the EC2 instance ID and the external DNS name.
</ul>

**--provision_only**
<ul>
This skips configuration of the local environment and runs  only
the  ansible scripts.  See the 'DETAILS' section below for addi‐
tional information.
</ul>

## Details
If the '--provision_only' option is not specified the  environment  for
pulling down the code and running the Ansible playbooks will be config‐
ured.  This will require sudo root access to the system  and  a  prompt
will be provided for the sudo password.  It is *NOT* recommended to run
this script as root.

To build the environment 'git' and 'python-pip' will be  installed  via
the  apt package management system.  Once installed, pip is utilized to
install 'python-boto', 'pyYaml' and 'jinja2'.  These are  all  required
for  proper  operation  of Ansible.  The Ansible GIT repository will be
cloned.  Branch 'release1.8.2' is used.  This is the end of  the  envi‐
ronment configuration.

With  these  in  place  the st-mp playbooks are fetched from github.  A
clone of 'https://github.com/Geryon/st-mp'  is  performed.   This  will
save  everything in '~/st-mp'.  After this is completed there is a sub‐
directory that contains all sensitive data, AWS keys, public keys (some
private  keys  specifically  for this project) and user configurations,
will be downloaded from S3 and  uncompressed  in  to  '~/st-mp/secure'.
Take  note of that directory as it will be required to be passed to the
Ansible playbook command via the '--extra' option.   Everything  beyond
here is performed regardless of the '--provision_only' option.

The  system  is  in  place at this point.  What is left is to set a few
variables.  Ansible provides a script to configure the environment when
running  Ansible from GIT, this is '~/ansible/hacking/env-setup', which
is sourced in to the current shell.  Additionally,  we  disable  strict
host   key   checking   in   OpenSSL  for  Ansible  by  setting  'ANSI‐
BLE_HOST_KEY_CHECKING=False'.  At this point the ansible playbook  com‐
mand can be ran.  This is an example of that command:

```
ansible-playbook -i localhost, st-mp/playbooks/stelligent-mp.yml -e 'secure_dir="/home/nick/st-mp/secure" hostname="st-mp-01" mail_to="nick@declario.com"' -t provision,deploy
```

##See Also
  man(1)  git(1)  apt-get(8)  pip(1)

##Bugs
  st-mp-deploy.sh is a work in progress.  Please report bugs.

##Author
  Nicholas DeClario <nick@declario.com>
