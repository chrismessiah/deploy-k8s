# Accessing Vault

```bash
export VAULT_ADDR="http://127.0.0.1:8200/"
export VAULT_TOKEN="s.Ga5jyNq6kNfRMVQk2LY1j9iu"

# initalize vault
vault operator init

# unseal Vault as described in
# https://learn.hashicorp.com/vault/getting-started/deploy#seal-unseal
vault operator unseal

vault status

# login after vault has been unsealed
vault login TOKEN

# lock vault again
vault operator seal

# allow Kubernetes authentication method using Kubernetes Service Account Tokens
# more auth methods are available at
# https://www.vaultproject.io/docs/auth/index.html
vault auth enable kubernetes
vault auth enable ldap
vault auth enable cert

# create a role in vault for the K8 auth method
vault write auth/kubernetes/login role=demo jwt=TOKEN???

# access UI
curl http://127.0.0.1:8200/ui/
```
