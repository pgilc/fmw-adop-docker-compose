#!/bin/bash -e

rm -fr mail-config

mkdir -p mail-config

docker run --rm -e MAIL_USER=${INITIAL_ADMIN_USER}@${LDAP_DOMAIN} -e MAIL_PASS=${INITIAL_ADMIN_PASSWORD_PLAIN} tvial/docker-mailserver:v2 /bin/sh -c 'echo "$MAIL_USER|$(doveadm pw -s SHA512-CRYPT -u $MAIL_USER -p $MAIL_PASS)"' >> mail-config/postfix-accounts.cf

docker run --rm -v "$(pwd)/mail-config":/tmp/docker-mailserver tvial/docker-mailserver:v2 generate-dkim-config

