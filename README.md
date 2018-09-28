# ps-kube-infra
Here lies Pixel Serving's initial Kube infrastructure YAMLs for GKE.

These YAMLs are to be applied before any application-related operations are attempted. 

Currently, these files set up:
1. ETCD in its own namespace.
2. Exposes ETCD in default namespace.

To apply, run in order:
```
kubectl apply -f core
kubectl apply -f ns-default
kubectl apply -f ns-etcd
```

## Verify ETCD
To check ETCD came up fine:
1. `kubectl logs -f etcd-0 -n etcd` - logs should not show any error.
2. `kubectl get pod -n etcd` should show the precise number of pods specified in `etcd.yaml`.
3. SSH into an etcd pod and check cluster-health is normal.
```
kubectl exec -it etcd-0 -n etcd sh (ssh into an etcd pod)
etcdctl cluster-health (shows cluster health)
```
Correct output:
```
/ # etcdctl cluster-health
member 1444d0f3d77d3ac7 is healthy: got healthy result from http://etcd-4.etcd:2379
member 2e80f96756a54ca9 is healthy: got healthy result from http://etcd-0.etcd:2379
member 7fd61f3f79d97779 is healthy: got healthy result from http://etcd-1.etcd:2379
member 9d19de8b7ec072f4 is healthy: got healthy result from http://etcd-3.etcd:2379
member b429c86e3cd4e077 is healthy: got healthy result from http://etcd-2.etcd:2379
cluster is healthy
```
