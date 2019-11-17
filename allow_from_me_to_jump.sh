# Get my own IP address
MY_IP_ADDRESS=$(curl http://checkip.amazonaws.com/)

# Default profile executing aws cli
DEFAULT_PROFILE=${1:-sls_admin_role}


STACK_TO_UPDATE=${2:-Sg}
PARAM_KEY_TO_UPDATE="MyIpAddress"
echo "My IP address is $MY_IP_ADDRESS"

# Parameter list to update
LIST_OF_PARAMS="ParameterKey=$PARAM_KEY_TO_UPDATE,ParameterValue=$MY_IP_ADDRESS/32"
# LIST_OF_PARAMS="ParameterKey=$PARAM_KEY_TO_UPDATE,ParameterValue=８/32"
# LIST_OF_PARAMS="ParameterKey=$PARAM_KEY_TO_UPDATE,ParameterValue=8.8.8.8/32"


echo "Allow my jump server security group to access from $LIST_OF_PARAMS in SSH."

# Execute updating stack
aws cloudformation update-stack --profile $DEFAULT_PROFILE --use-previous-template --stack-name $STACK_TO_UPDATE --parameters $LIST_OF_PARAMS

# Check No updates are to be performed.
ret_val=$?
if [ $ret_val -eq 255 ];then
    echo "There is nothing to be updated."
    exit
fi

while true
do

    # Get stack status
    test=$(aws cloudformation describe-stack-events \
        --profile $DEFAULT_PROFILE \
        --stack-name $STACK_TO_UPDATE \
        --max-items 1)
    stack_event="$(echo $test | jq '."StackEvents"[0]."ResourceStatus"'| tr -d '""')"
    event_reason="$(echo $test | jq '."StackEvents"[0]."ResourceStatusReason"'| tr -d '""')"
    logical_id="$(echo $test | jq '."StackEvents"[0]."LogicalResourceId"'| tr -d '""')"

    echo "$logical_id is $stack_event because $event_reason"

    # Check stack status
    if [ $stack_event = "UPDATE_ROLLBACK_COMPLETE" ] || [ $stack_event = "UPDATE_COMPLETE" ];then
        echo "Yes $stack_event"
        if [ $logical_id = $STACK_TO_UPDATE ];then
            echo "Stack change is finished"
            exit
        fi
    fi
    sleep 10s

done
