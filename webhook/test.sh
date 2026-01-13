kubectl create namespace monitoring

helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f alertmanager-values.yaml

kubectl get pods -n monitoring

kubectl apply -f prometheus-rule.yaml
