Write-Output "--- Nettoyage de l'environnement ---"
# Suppression des stacks existantes
Write-Output "--- Nettoyage des Stacks ---"
docker stack rm wosa_infra wosa_service_mesh wosa_messaging

Write-Output "Attente de la suppression complète des conteneurs..."
# Boucle pour attendre que les conteneurs libèrent le réseau
$RETRIES = 10
while ($RETRIES -gt 0) {
    # On vérifie si des conteneurs utilisent encore public_net
    if ([string]::IsNullOrWhiteSpace($(docker network inspect -f '{{range .Containers}}{{.Name}} {{end}}' public_net 2>$null))) {
        Write-Output "Réseau public_net libéré."
        break
    }
    Write-Output "Le réseau est encore utilisé, attente... ($RETRIES)"
    Start-Sleep 3
    $RETRIES--
}

# docker stack rm wosa_infra wosa_service_mesh
# docker network prune -f
# docker network rm public_net
# $networkCheck = docker network ls --filter name=^public_net$ --format "{{.Name}}"
# Write-Output $networkCheck
# if (-not $networkCheck) {
#     Write-Host "Création du réseau public_net..."
#     docker network create --driver overlay --attachable public_net
# }
# Attendre que les ressources soient libérées par Swarm
Write-Host "Création du réseau public_net..."
docker network create --driver overlay --attachable public_net
Write-Output "Attente de la libération des ressources (15s)..."
Start-Sleep 15

# Nettoyage des réseaux inutilisés pour éviter les conflits

# Création manuelle du réseau pour éviter les préfixes de stack
# --- CONFIGURATION DES MOTS DE PASSE ---
$DB_PWD = "lopez_admin2026*"  # À modifier
$ADMIN_PWD = "lopez_admin2026*"   # À modifier

# --- CRÉATION DES SECRETS DOCKER ---
# On utilise Write-Output pour envoyer la chaîne vers l'entrée standard de docker secret
Write-Output $DB_PWD | docker secret create db_password -
Write-Output $ADMIN_PWD | docker secret create admin_password -

# --- DÉPLOIEMENT ---
# Déploiement de la Gateway (Traefik + Keycloak)
docker stack deploy -c stack-gateway.yml wosa_infra

# Déploiement de Consul
docker stack deploy -c stack-consul.yml wosa_service_mesh

# Déploiement de Nats
docker stack deploy -c stack-nats.yml wosa_messaging