### Test and build the proxy binary

```console
go test ./pilot/pkg/cri/
make pilot-node-agent
```

### Create a Kind cluster with 1 worker

```console
kind create cluster --name=test --config=- <<EOF
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
- role: worker
EOF
```

```console
export KUBECONFIG=$(kind get kubeconfig-path --name="test")
```

### Install the proxy binary onto the worker node

```console
docker cp $GOPATH/out/linux_amd64/release/pilot-node-agent test-worker:/usr/local/bin
```

### In a separate shell, start the proxy binary on the worker node.

```console
docker exec -ti test-worker /usr/local/bin/pilot-node-agent cri-proxy
```

### Create the temp files on the worker node

```console
docker exec -ti test-worker /bin/bash
mkdir -p /tmp/test/etc-istio-proxy
chmod 777 /tmp/test/etc-istio-proxy
mkdir -p /tmp/test/etc-certs
chmod 555 /tmp/test/etc-certs
```

```console
cat >/tmp/test/etc-hosts <<EOF
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
fe00::0	ip6-mcastprefix
fe00::1	ip6-allnodes
fe00::2	ip6-allrouters
EOF
```

### Install Istio (e.g. version 1.2.2 here) using the minimal profile

```console
cd ~
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.2.2 sh -
cd istio-1.2.2
kubectl create namespace istio-system
helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l
helm template install/kubernetes/helm/istio --name istio --namespace istio-system \
    --values install/kubernetes/helm/istio/values-istio-minimal.yaml | kubectl apply -f -
```

### Setup the woker's node kubelet to use the proxy's CRI socket

```console
docker exec test-worker /bin/bash -c \
'echo "KUBELET_KUBEADM_ARGS=--container-runtime=remote \
--container-runtime-endpoint=/var/run/istio-pilot-node-agent.sock" > /var/lib/kubelet/kubeadm-flags.env'

docker exec test-worker systemctl restart kubelet
```

### Create a pod and service, WITHOUT Istio injection

```console
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: helloworld
  labels:
    app: helloworld
spec:
  ports:
  - port: 5000
    name: http
  selector:
    app: helloworld
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: helloworld
spec:
  template:
    metadata:
      labels:
        app: helloworld
    spec:
      containers:
      - name: helloworld
        image: istio/examples-helloworld-v1
        resources:
          requests:
            cpu: "100m"
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
EOF
```
