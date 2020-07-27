#!/usr/bin/env bash

appUrlBase="http://127.0.0.1:8080"

actuator_health_reply_expected='{"status":"UP"}'
actuator_health_reply="$( curl -s ${appUrlBase}/actuator/health )"
#echo "actuator_health_reply is ${actuator_health_reply}"
if [ "${actuator_health_reply}" != "${actuator_health_reply_expected}" ]; then
  echo "ERROR: actuator/health did not reply with \"${actuator_health_reply_expected}\" but instead replied with: ${actuator_health_reply}"
  exit 1
fi

echo "LOCALDEV test script completed successfully."
