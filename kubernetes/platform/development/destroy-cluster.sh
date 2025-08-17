#!/bin/sh

echo "\n🏴️ Destroying Kubernetes cluster...\n"
# 프로필 정리
minikube stop --profile bookshop 2>/dev/null || true

minikube delete --profile bookshop --all --purge
# kube 캐시도 리셋 (디스커버리 캐시 꼬임 방지)
rm -rf ~/.kube/cache ~/.kube/http-cache

echo "\n🏴️ Cluster destroyed\n"
