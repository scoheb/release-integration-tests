#!/usr/bin/env sh

# trap teardown EXIT

DEV_KUBECONFIG="--kubeconfig=/home/kasemalem/rhtap_kubeconfigs/stage_dev_release_kubelogin"
MANAGED_KUBECONFIG="--kubeconfig=/home/kasemalem/rhtap_kubeconfigs/stage_managed_release_kubelogin"

MANAGED_NAMESPACE="managed-release-team-tenant"
APPLICATION_NAME="e2e-fbc-application"
COMPONENT_NAME="e2e-fbc-component"
RELEASE_PLAN_NAME="e2e-fbc-releaseplan"
RELEASE_PLAN_ADMISSION_NAME="e2e-fbc-releaseplanadmission"
RELEASE_STRATEGY_NAME="e2e-fbc-strategy"
TIMEOUT_SECONDS=600

function setup() {
    
    
    echo "Creating Application"
    kubectl apply -f release-resources/application.yaml "$DEV_KUBECONFIG"

    echo "Creating Component"
    kubectl apply -f release-resources/component.yaml "$DEV_KUBECONFIG"
    
    echo "Creating ReleaseStrategy"
    kubectl apply -f release-resources/release-strategy.yaml "$MANAGED_KUBECONFIG"

    echo "Creating ReleasePlan"
    kubectl apply -f release-resources/release-plan.yaml "$DEV_KUBECONFIG"

    echo "Creating ReleasePlanAdmission"
    kubectl apply -f release-resources/release-plan-admission.yaml "$MANAGED_KUBECONFIG"

}

function teardown() {
    echo "Debug: "$DEBUG""
 
    kubectl delete pr -l "appstudio.openshift.io/application="$APPLICATION_NAME",pipelines.appstudio.openshift.io/type="$type",appstudio.openshift.io/component="$COMPONENT_NAME"" "$DEV_KUBECONFIG"
    kubectl delete pr -l "appstudio.openshift.io/application="$APPLICATION_NAME",pipelines.appstudio.openshift.io/type="$type"" "$MANAGED_KUBECONFIG"

    #kubectl delete release -o=jsonpath="{.spec.releasePlan}{'\n'}{end}"
    kubectl delete release "$DEV_KUBECONFIG" -o=jsonpath='{.items[?(@.spec.releasePlan=="$RELEASE_PLAN_NAME")].metadata.name}'
    kubectl delete releaseplan "$RELEASE_PLAN_NAME" "$DEV_KUBECONFIG"
    kubectl delete releaseplanadmission "$RELEASE_PLAN_ADMISSION_NAME" "$MANAGED_KUBECONFIG"
    kubectl delete releasestrategy "$RELEASE_STRATEGY" "$MANAGED_KUBECONFIG"

    if kubectl get application "$APPLICATION_NAME"  "$DEV_KUBECONFIG" &> /dev/null; then
        echo "Application '"$APPLICATION_NAME"' exists. Deleting..."
        kubectl delete application "$APPLICATION_NAME" "$DEV_KUBECONFIG"
    else
        echo "Application '"$APPLICATION_NAME"' does not exist."
    fi
}

# Function to check the status of argument $1 CRD contains labels $2 CRD labels
function wait_for_pr_to_complete() {
    local kube_config
    local type=$1
    local start_time=$(date +%s)

    if [ "$type" = "release" ]; then
        kube_config="$MANAGED_KUBECONFIG"
        crd_labels="appstudio.openshift.io/application="$APPLICATION_NAME",pipelines.appstudio.openshift.io/type="$type""
    else
        kube_config="$DEV_KUBECONFIG"
        crd_labels="appstudio.openshift.io/application="$APPLICATION_NAME",pipelines.appstudio.openshift.io/type="$type",appstudio.openshift.io/component="$COMPONENT_NAME""
    fi

    while true; do        
        crd_json=$(kubectl get PipelineRun -l "$crd_labels" "$kube_config" -o=json)
        
        reason=$(echo "$crd_json" | jq -r '.items[0].status.conditions[0].reason')
        status=$(echo "$crd_json" | jq -r '.items[0].status.conditions[0].status')
        type=$(echo "$crd_json" | jq -r '.items[0].status.conditions[0].type')
        name=$(echo "$crd_json" | jq -r '.items[0].metadata.name')
        namespace=$(echo "$crd_json" | jq -r '.items[0].metadata.namespace')
        
        if [ "$status" = "False" ] || [ "$type" = "Failed" ]; then
            echo "PipelineRun "$name" failed."
            return 1
        fi
        
        if [ "$status" = "True" ] && [ "$reason" = "Completed" ] && [ "$type" = "Succeeded" ]; then
            echo "PipelineRun "$name" succeeded."
            return 0
        else
            current_time=$(date +%s)
            elapsed_time=$((current_time - start_time))

            if [ "$elapsed_time" -ge "$TIMEOUT_SECONDS" ] ; then
                echo "Timeout: PipelineRun "$name" in namespace "$namespace" did not succeeded within $TIMEOUT_SECONDS seconds."
                return 1
            fi
            echo "Waiting for PipelineRun "$name" in namespace "$namespace" to succeed."
            sleep 5
        fi
    done
}

echo "Seting up resoures"
setup

echo "Wait for build PipelineRun to finish"
wait_for_pr_to_complete "build"

echo "Wait for release PipelineRun to finish"
wait_for_pr_to_complete "release"

echo "Waiting for the Release to be updated"
sleep 10

echo "Checking Release status"
# Get name of Release CR associated with Release Strategy "e2e-fbc-strategy".
release_name=$(kubectl get release  "$DEV_KUBECONFIG" -o jsonpath="{range .items[?(@.status.processing.releaseStrategy=='$MANAGED_NAMESPACE/$RELEASE_STRATEGY_NAME')]}{.metadata.name}{'\n'}{end}")

# Get the Released Status and Reason values to identify if fail or succeeded
release_status=$(kubectl get release "$release_name" "$DEV_KUBECONFIG" -o jsonpath='{.status.conditions[?(@.type=="Released")].status}')
release_reason=$(kubectl get release "$release_name" "$DEV_KUBECONFIG" -o jsonpath='{.status.conditions[?(@.type=="Released")].reason}')

if [ "$release_status" = "True" ] && [ "$release_reason" = "Failed"]; then
    echo "Rlease "$release_name" Released succeeded."
else 
    echo "Rlease "$release_name" Released Failed."
fi

