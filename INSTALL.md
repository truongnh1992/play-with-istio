# Installing istio
```console
curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.1.0 sh -
```

```console
for i in install/kubernetes/helm/istio-init/files/crd*yaml; do sudo kubectl apply -f $i; done
```

```console
sudo kubectl apply -f install/kubernetes/istio-demo.yaml
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

```console
sudo kubectl label namespace default istio-injection=enabled
```

```console
sudo kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

# Cleaning Bookinfo
```console
samples/bookinfo/platform/kube/cleanup.sh
```
