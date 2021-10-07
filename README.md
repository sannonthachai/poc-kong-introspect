# poc-kong-introspect

kubectl create ns kong

kubectl create configmap kong-plugin-custom-auth --from-file=custom-auth -n kong

helm install kong/kong --generate-name --namespace kong --set ingressController.installCRDs=false --values values.yaml

