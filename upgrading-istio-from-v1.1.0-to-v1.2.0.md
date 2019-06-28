## Upgrading Istio from v1.1.0 to v1.2.0

Follow [this guide](INSTALL-Istio-Bookinfo.md) to install Istio v1.1.0

In order to minimize downtime when upgrading Istio, please ensure that deploying Bookinfo with multiple replicas.  
Change all replicas from 1 to 3 and insert `readinessProbe` under Deployment productpage-v1 in `bookinfo.yaml` 

```console
vim samples/bookinfo/platform/kube/bookinfo.yaml
```
```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: productpage-v1
  labels:
    app: productpage
    version: v1
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: productpage
        version: v1
    spec:
      containers:
      - name: productpage
        image: istio/examples-bookinfo-productpage-v1:1.10.1
        imagePullPolicy: IfNotPresent
        readinessProbe:
          tcpSocket:
            port: 9080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 2
        ports:
        - containerPort: 9080
```

### Control plane upgrade

Download istio v1.2.0 and change directory to the new release directory
```console
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.2.0 sh -
cd istio-1.2.0
```

#### 1. Backing up your custom resource data, before proceeding with the upgrade 

```console
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | cut -f1-1 -d "." | \
xargs -n1 -I{} sh -c "kubectl get --all-namespaces -oyaml {}; echo ---" > $HOME/ISTIO_1_0_RESTORE_CRD_DATA.yaml
```
#### 2. Use `kubectl apply` to upgrade all the Istio's CRDs
```console
for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
```

#### 3. Add Istio's core components to a Kubernetes manifest file
```console
helm template install/kubernetes/helm/istio --name istio --namespace istio-system > $HOME/istio.yaml
```
#### 4. Upgrade the Istio control plane components
```console
kubectl apply -f $HOME/istio.yaml
```

### Sidecar upgrade

Using this bash script (upgrade-sidecar.sh) which triggers the rolling update by patching the grace termination period.
```sh
# based on the "patch deployment" strategy in this comment:
# https://github.com/kubernetes/kubernetes/issues/13488#issuecomment-372532659
# requires jq

# $1 is a valid namespace

if [ $# -ne 1 ]; then
    echo $0": usage: ./refresh.sh <namespace>"
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
```

Upgrade sidecar
```console
./upgrade-sidecar.sh default
```
