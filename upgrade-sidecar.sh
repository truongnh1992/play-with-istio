# Credit: @jmound (https://github.com/jmound) and @adinunzio84 (https://github.com/adinunzio84)
# based on the "patch deployment" strategy in this comment:
# https://github.com/kubernetes/kubernetes/issues/13488#issuecomment-372532659
# requires jq

# $1 is a valid namespace

if [ $# -ne 1 ]; then
    echo $0": usage: ./upgrade-sidecar.sh <namespace>"
    exit 1
fi

NS=$1

function refresh-all-pods() {
    echo
    DEPLOYMENT_LIST=$(kubectl -n $NS get deployment -o jsonpath='{.items[*].metadata.name}')
    echo "Refreshing pods in all Deployments"
    for deployment_name in $DEPLOYMENT_LIST ; do
        TERMINATION_GRACE_PERIOD_SECONDS=$(kubectl -n $NS get deployment "$deployment_name" -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}')
    if [ "$TERMINATION_GRACE_PERIOD_SECONDS" -eq 30 ]; then
        TERMINATION_GRACE_PERIOD_SECONDS='31'
    else
        TERMINATION_GRACE_PERIOD_SECONDS='30'
    fi
    patch_string="{\"spec\":{\"template\":{\"spec\":{\"terminationGracePeriodSeconds\":$TERMINATION_GRACE_PERIOD_SECONDS}}}}"
    kubectl -n $NS patch deployment $deployment_name -p $patch_string
done
echo
}

refresh-all-pods $NAMESPACE
