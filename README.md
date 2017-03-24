# Sypnosis
---

This is a forked project of [Accenture DevOps Platform](https://github.com/accenture/adop-docker-compose) that is extended for the following purposes:

- To use Gitlab instead of Gerrit as the main Git repository to load cartridges and performs CI/CD because we/our clients like Gitlab more.
- To have a built-in Ansible jenkins slave container.
- To have a built-in SMTP docker container.  
- To have a customized Platform Extension with no regard to the original specification due to it's limited extension capability.

Due to the complexity of merging the code how we implemented the above, we decided to forked away this project and planned to collaborate in the future to see what the original ADOP project can re-use.

Here is the front page:  
![HomePage](https://raw.githubusercontent.com/AccenturePDC/adop-docker-compose/pdc-ext/img/adop_pdc_home_page.png)

# General Installation Guide
---
## Option 1 - Launch using AWS CloudFormation.

If you have an AWS account, you can get the cloudformation templates here: https://github.com/bzon/adop-cloudformation-template. Use the Single Node version for demo or sandbox environments.

## Option 2 - Launch from the command line.

If you want to launch this manually provided that you have basic knowledge in Linux command line and docker. Follow the steps below.

### System requirements:

**CPU**: 4 Core  
**RAM**: 16 GB  
**Disk Storage**: 100GB  
**Internet connection**  

### Linux packages required:
**docker-engine** v1.10 or higher.  
**docker-compose** v1.7 or higher.  
**git**


### Manual Installation steps:  

- Export Container global variables.

    - `CUSTOM_NETWORK_NAME` - The docker network name.
    - `TARGET_HOST` - Use the host internal ip address where the proxy is deployed.
    - `LOGSTASH_HOST` - Use the host internal ip address where the proxy is deployed.
    - `INITIAL_ADMIN_USER` - The initial user that will have an administrator access to all the tools.
    - `INITIAL_ADMIN_PASSWORD_PLAIN` - The initial user's password.
    - `ADOP_CLI_USER` - The cli user that has administrator access to Jenkins. This can be the `INITIAL_ADMIN_USER`
    - `ADOP_CLI_PASSWORD` - The cli user's password.
    - `SMTP_DOMAIN` - Your smtp server domain. 
    
    Or better create a script for these and source it.
    
    ```bash
    cat > my-vars.sh <<-EOF
    export PUBLIC_IP=52.52.15.15
    export CUSTOM_NETWORK_NAME=docker-network
    export TARGET_HOST=10.10.1.5
    export LOGSTASH_HOST=10.10.1.5
    export INITIAL_ADMIN_USER=juansmith
    export INITIAL_ADMIN_PASSWORD_PLAIN=beshy123
    export ADOP_CLI_USER=juansmith
    export ADOP_CLI_PASSWORD=beshy123
    export SMTP_DOMAIN=awsamazon.com # IMPORTANT: Use this domain if you are launching this from AWS EC2.
    EOF
    ```
    
- Set the LDAP credentials and load environment variables.

    ```bash
    # Load adop default variables
    source env.config.sh
    # Load your preference variables
    source my-vars.sh
    # Generate a `platform.secrets.sh` file that will automatically be sourced.
    source credentials.generate.sh
    ```

- Deploy the containers

    ```bash
    # Create the docker network
    docker network create ${CUSTOM_NETWORK_NAME}
    
    # Create the mail-server configurations
    compose/mail-server/setup_mailserver.sh
    # Deploy mail-server container
    docker-compose -f compose/mail-server/docker-compose.yml up -d
    
    # Deploy ELK stack containers
    docker-compose -f compose/elk.yml up -d
    
    ## Deploy PDC extensions of ADOP
    # Set docker-compose overrides
    COMPOSE_OVERRIDES='-f docker-compose.yml -f compose/gitlab/docker-compose.yml -f compose/jenkins-aws-vars/docker-compose.yml -f compose/jenkins-ansible-slave/docker-compose.yml'
    VOLUME_OVERRIDES='-f etc/volumes/local/default.yml' 
    # Deploy
    docker-compose ${COMPOSE_OVERRIDES} ${VOLUME_OVERRIDES} up -d
    ```
- (Optional) Load the Gitlab Platform in Jenkins and create initial Workspace and Project from the commandline.

    ```bash
    # Load the Gitlab platform job to generate the Workspace creator job
    ./gitlab-load-platform
    
    # Set variables using for adop cli
    ./adop target set -t http://${TARGET_HOST} -u ${ADOP_CLI_USER} -p ${ADOP_CLI_PASSWORD}
    # You will be prompted to source the target file
    source ./.adop/target
    
    # Create a sample workspace using adop cli.
    ./adop workspace -w MyWorkspace create -a ${INITIAL_ADMIN_USER}@${LDAP_DOMAIN}
    # Create a sample project using adop cli.
    ./adop project -w MyWorkspace -p MyProject create -a ${INITIAL_ADMIN_USER}@${LDAP_DOMAIN}
    ```

# Post Installation
---
## Configure Jenkins Gitlab connection to enable gitlab web hooks to trigger Jenkins CI/CD pipelines.

 - Get your Gitlab user Private Token.

  - You can get your gitlab user's *Private token* from the Gitlab's page url -  http://ADOPIPADDRESS/gitlab/profile/account. 

  - From the Jenkins Home Page, Go to *Credentials* and create a credentials with the *Gitlab API Token* type using the Account Token of the gitlab user. 

 - Configure Gitlab connection.

  - From the Jenkins Home Page, Go to *Manage Jenkins* >> *Configure System*, search for the Gitlab connection settings.

  ```bash
  Connection name: ADOP Gitlab
  Gitlab host URL: http://gitlab/gitlab
  Credentials: <the gitlab api token credentials you created>
  ```

  - Test the connection to ensure that Gitlab and Jenkins communicates with each other.


## Known Issue
---
- Fix for an issue where users will not be able to clone using ssh from Gitlab.  

    ```bash
    docker exec gitlab sed -i "s/session    required     pam_loginuid.so/session    optional     pam_loginuid.so/" /etc/pam.d/sshd
    ```
    Reference:  
    https://github.com/gitlabhq/gitlabhq/issues/6537  
    http://www.linuxweblog.com/blogs/sandip/20090203/setloginuid-failed-opening-loginuid 

