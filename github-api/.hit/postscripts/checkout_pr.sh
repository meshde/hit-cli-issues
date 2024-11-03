cd ../../tower-stack-game && git checkout `cat $HIT_RESPONSE_PATH | jq -r '.body' | jq -r '.head.ref'` && cd -
