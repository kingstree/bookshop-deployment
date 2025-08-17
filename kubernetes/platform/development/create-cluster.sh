#!/bin/sh

echo "\n📦 Initializing Kubernetes cluster...\n"

minikube start --cpus 2 --memory 8g --driver docker --profile bookshop

echo "\n🔌 Enabling NGINX Ingress Controller...\n"

minikube addons enable ingress --profile bookshop

sleep 30

echo "\n📦 Deploying Keycloak..."

kubectl apply -f services/keycloak-config.yml
kubectl apply -f services/keycloak.yml

sleep 5

echo "\n⌛ Waiting for Keycloak to be deployed..."

while [ $(kubectl get pod -l app=bookshop-keycloak | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for Keycloak to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app=bookshop-keycloak \
  --timeout=300s

echo "\n⌛ Ensuring Keycloak Ingress is created..."

kubectl apply -f services/keycloak.yml

echo "\n📦 Deploying PostgreSQL..."

kubectl apply -f services/postgresql.yml

sleep 5

echo "\n⌛ Waiting for PostgreSQL to be deployed..."

while [ $(kubectl get pod -l db=bookshop-postgres | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for PostgreSQL to be ready (first attempt)..."

if ! kubectl wait \
  --for=condition=ready pod \
  --selector=db=bookshop-postgres \
  --timeout=180s ; then
  echo "\n⚠️  PostgreSQL not ready in time — applying init-config detach patch..."
  kubectl patch deploy bookshop-postgres --type=json -p='[
    {"op":"remove","path":"/spec/template/spec/containers/0/volumeMounts/0"},
    {"op":"remove","path":"/spec/template/spec/volumes/0"}
  ]'
  echo "\n🔁 Restarting PostgreSQL deployment after patch..."
  kubectl rollout restart deploy/bookshop-postgres
  echo "\n⌛ Waiting for PostgreSQL to be ready (after patch)..."
  kubectl wait \
    --for=condition=ready pod \
    --selector=db=bookshop-postgres \
    --timeout=60s
fi

echo "\n📦 Deploying Redis..."

kubectl apply -f services/redis.yml

sleep 5

echo "\n⌛ Waiting for Redis to be deployed..."

while [ $(kubectl get pod -l db=bookshop-redis | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for Redis to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=bookshop-redis \
  --timeout=180s

echo "\n📦 Deploying RabbitMQ..."

kubectl apply -f services/rabbitmq.yml

sleep 5

echo "\n⌛ Waiting for RabbitMQ to be deployed..."

while [ $(kubectl get pod -l db=bookshop-rabbitmq | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for RabbitMQ to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=bookshop-rabbitmq \
  --timeout=180s

echo "\n📦 Deploying bookshop UI..."

kubectl apply -f services/bookshop-ui.yml

sleep 5

echo "\n⌛ Waiting for bookshop UI to be deployed..."

while [ $(kubectl get pod -l app=bookshop-ui | wc -l) -eq 0 ] ; do
  sleep 5
done

echo "\n⌛ Waiting for bookshop UI to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app=bookshop-ui \
  --timeout=10s

echo "\n⛵ Happy Sailing!\n"
