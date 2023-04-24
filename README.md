## InfoBlox DNS Records Webhook in Kubernetes cluster
### Motivation
To automate the creation of DNS records in Infoblox DNS servers when Kubernetes ingress resources are created.
Use of [External DNS](https://github.com/kubernetes-sigs/external-dns) controller was found to be inadequate, perhaps due to the development stage of Infoblox
provider in External DNS. To overcome this shortcoming in External DNS, a webhook was created.
The webhook examines the ingress resource, extracts the host information sends a request to the Infoblox for
creation/deletion of DNS records. 

### Prerequisites
- Go installation
- Local Kubernetes cluster
- The following commandline utilities:
    - `make`
    - `kubectl`
    - `helm`
- Access to an Infoblox test instance

### Getting started 
- Deployment on local kubernetes cluster
1. Clone the [repository](https://github.com/middlewaregruppen/external-dns-webhook)
2. Change into the directory, `external-dns-webhook`
3. Test that the binary can be created
```yaml
make test
```
4. Install the webhook into the target kubernetes cluster.
- The following will be deployed:
    - A docker image will be built and pushed to the container registry of choice
    - Self-signed SSL certificates will be created and used to create a TLS secret
    - A deployment will be created in the target kubernetes cluster
    - A mutating and validating webhook is created in the cluster.
    - *Note the service requires access to the ingress controller namespace to read the LoadBalancer service attributes,i.e. IP address

- Set the kubernetes context
```yaml
kubectl config use-context <<CONTEXT>>
# Example: kubectl config kind-cluster
```
- Deploy webhook
```yaml
make deploy CONTAINER_REGISTRY=<<TARGET_CONTAINER_REGISTRY>> WEBHOOK_NAMESPACE=<<NAMESPACE>> TAG=<<VERSION>>
# Example: make deploy CONTAINER_REGISTRY=registry.localdev.me WEBHOOK_NAMESPACE=sbx TAG=v0.0.1
```

### Cleanup of local deployment
To remove the deployed webhook resources, run the following:
```yaml
make clean
```

### Deployment in "Production-like" Kubernetes cluster
```
helm repo add infoblox-dns-webhook https://middlewaregruppen.github.io/helm-charts
helm repo update
helm install infoblox-dns-webhook -n infoblox-dns --create-namespace -f values.yaml ..create-namespace
```
The following variables are used to deploy the webhook

| NAME | Description | Type | Default |
| ---------- | :-------------- | :--------------- | -------------------- |
| repository | Container registry where image is stored | string  | registry.localdev.me |
| infobloxInfo.port | Port of the InfoBlox Server port | integer | 443 |
| infobloxInfo.protocol | HTTP/HTTPS protocol | string | https |
| infobloxInfo.server | Domain name or IP of InfoBlox Server | string | infoblox.localdev.me |
| infobloxInfo.version | InfoBlox version | string | v2.12.1 |
| infobloxInfo.view | Infoblox DNS view | string | default.localdev |
| infobloxInfo.zone | InfoBlox DNS zone (DNS suffix) | string | localdev.me |
| infobloxInfo.secret.username | InfoBlox Server user | string | admin |
| infobloxInfo.secret.password | InfoBlox Server password | string | p4ssw0rd |
| infobloxInfo.secret.name | Name of secret holding InfoBlox user credentials | string | infoblox-creds |
| project.name | Name of the webhook used in the admission webhook manifests | string | infoblox-dns-webhook |
| tls.name | Name of TLS certificate secret | string | infoblox-dns-webhook-tls |
| tls.cert | TLS certificate content in Base64 | string | - |
| tls.key | TLS key content in Base64 | string | - |

### Example installation with a self-signed certificate:
- Create a self-signed certificate
```yaml
openssl genrsa -out tls.key
openssl req -new -key tls.key --out tls.csr -subj "/CN=example-hook.example-ns.svc"
openssl x509 -req -extfile <(printf 'subjectAltName=DNS:example-hook.example-ns.svc') -in tls.csr -signkey tls.key -out tls.crt
```
- Install the helm chart
```yaml
helm install infoblox-dns-webhook ./infoblox-dns-webhook -n infoblox-dns --create-namespace \
    --set image.repository=registry.localdev.me/external-dns-webhook/external-dns-webhook \
    --set image.tag=v0.1.1 \
    --set tls.cert=$(cat tls.crt | base64 | tr -d '\n') \
    --set tls.key=$(cat tls.key | base64 | tr -d '\n')
```

