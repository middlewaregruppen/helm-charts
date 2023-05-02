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
- Access to an Infoblox Server test instance

### Getting started
```
helm repo add infoblox-dns-webhook https://middlewaregruppen.github.io/helm-charts
helm repo update
```

- Create/update a `values.yaml` file with values suitable for the target environment
```
helm install infoblox-dns-webhook -n infoblox-dns --create-namespace -f values.yaml
```
The following variables are used to deploy the webhook

| NAME | Description | Type | Default |
| ---------- | :-------------- | :--------------- | -------------------- |
| clusterInfo.name | Name of the cluster where webhook is deployed | string | - |
| clusterInfo.ingressControllerNamespace | Namespace where ingress controller is deployed | string | ingress-nginx |
| clusterInfo.ingressControllerName | Ingress controller serviceName | string | ingress-nginx-controller |
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
| repository | Container registry where image is stored | string  | registry.localdev.me |
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
helm install infoblox-dns-webhook infoblox-dns-webhook/infoblox-dns-webhook -n infoblox-dns --create-namespace \
    --set tls.cert=$(cat tls.crt | base64 | tr -d '\n') \
    --set tls.key=$(cat tls.key | base64 | tr -d '\n') \
    --set infobloxInfo.server=infoblox.localdev.me \
    --set infobloxInfo.secret.username=infoblox \
    --set infobloxInfo.secret.password=p4ssword \
    --set clusterInfo.name=infra-tools-dev \
    --set clusterInfo.ingressControllerNamespace=infra-apps-dev \
    --set clusterInfo.ingressControllerName=infra-apps-controller
```