# Installing istio

### 1. Download Istio
```console
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.1.0 sh -
```
### 2. Install all the Istio Custom Resource Definitions (CRDs)
```console
for i in install/kubernetes/helm/istio-init/files/crd*yaml; do kubectl apply -f $i; done
```

### 3. Install istio-demo
```console
kubectl apply -f install/kubernetes/istio-demo.yaml
```

**Note:**  
1. Set no_proxy
```console
export no_proxy=localhost,127.0.0.1,10.164.178.0/24
```
2. Force delete pod stuck in terminating status
```console
kubectl delete pod $POD_NAME -n $NAMESPACE --grace-period=0 --force
```

# Installing Bookinfo app

### 1. Label the namespace that will host the application with `istio-injection=enabled`
```console
kubectl label namespace default istio-injection=enabled
```

### 2. Deploy Bookinfo application
```console
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

# Cleaning Bookinfo
```console
samples/bookinfo/platform/kube/cleanup.sh
```
