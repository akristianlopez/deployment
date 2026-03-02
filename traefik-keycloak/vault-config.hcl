ui = true
disable_mlock = true

# Define how Vault listens for requests
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = "true"  # Set to "false" and provide certs for production
}

storage "raft" {
  path    = "/vault/file"
  node_id = "knb"
}

api_addr     = "http://127.0.0.1:8800"

# Adresse pour la communication interne du cluster Raft
cluster_addr = "http://127.0.0.1"