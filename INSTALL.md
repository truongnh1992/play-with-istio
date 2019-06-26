## Installing istio

### 1. Download Istio
```console
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.1.0 sh -
```
### 2. Install all the Istio Custom Resource Definitions (CRDs)
```console
cd istio-1.1.0
for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
```

### 3. Install istio-demo
```console
kubectl apply -f install/kubernetes/istio-demo.yaml
```

**Note:**  
1. Set no_proxy

`export no_proxy=localhost,127.0.0.1,10.164.178.0/24`

2. Force delete pod stuck in terminating status

`kubectl delete pod $POD_NAME -n $NAMESPACE --grace-period=0 --force`

### 4. Uninstall Istio

```console
kubectl delete -f install/kubernetes/istio-demo.yaml

for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl delete -f $i; done
```

## Installing Bookinfo app

### 1. Label the namespace that will host the application with `istio-injection=enabled`
```console
kubectl label namespace default istio-injection=enabled
```

### 2. Deploy Bookinfo application
```console
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

To confirm that the Bookinfo application is running.
```console
kubectl exec -it $(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}') -c ratings -- curl productpage:9080/productpage | grep -o "<title>.*</title>"

<title>Simple Bookstore App</title>
```

### 3. Clean Bookinfo
```console
samples/bookinfo/platform/kube/cleanup.sh
```

## Determining the ingress IP and port

### 1. Define the ingress gateway for the application
```console
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

### 2. Confirm the gateway has been created
```console
kubectl get gateway

NAME               AGE
bookinfo-gateway   32s
```

### 3. Set the `INGRESS_HOST` and `INGRESS_PORT` for accessing the gateway

Setting the ingress ports:
```console
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
```

Setting the ingress IP:
```console
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
```

### 4. Set `GATEWAY_URL`
```console
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
```

### 5. Confirm the app is accessible from outside the cluster
Using web browser and goto `http://${GATEWAY_URL}/productpage` or:
```console
curl -s http://${GATEWAY_URL}/productpage | grep -o "<title>.*</title>"

<title>Simple Bookstore App</title>
```

