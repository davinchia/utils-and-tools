# ps-kube-infra
Here lies Pixel Serving's initial Kube infrastructure YAMLs for GKE.

These YAMLs are to be applied before any application-related operations are attempted. 

Currently, these files set up:
1) ETCD in its own namespace.
2) Exposes ETCD in default namespace.

To apply, run in order:
kubectl apply -f core
kubectl apply -f ns-default
kubectl apply -f ns-etcd

