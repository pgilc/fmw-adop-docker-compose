#!/bin/bash -e

replace_tokens() {
 replacement=$(env | grep $token | awk -F= '{print $2}')
 if [[ $(cat ${NEW_FILE} | grep "###${token}###" | wc -l) -gt 0 ]]; then
   echo "File=${NEW_FILE}, Token=###${token}###, Replacement=${replacement}"
   sed "s+###${token}###+${replacement}+g" -i ${NEW_FILE}
 fi
}

VARS_PREFIX="AWS_"
TEMPLATE_FILE="../../conf/provider/examples/env.provider.aws.sh.example"
NEW_FILE="../../conf/provider/env.provider.aws.sh"

cat ${TEMPLATE_FILE} > ${NEW_FILE}
declare -a VARS_TOKENS=$(env | grep ^"${VARS_PREFIX}" | awk -F= '{print $1}')
for token in ${VARS_TOKENS[@]}
do
  replace_tokens
done

