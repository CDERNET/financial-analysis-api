# Trial Balance Extractor - Kubernetes Deployment Guide

Bu rehber, Trial Balance Extractor uygulamasının Kubernetes cluster'ına deploy edilmesi için gerekli adımları içermektedir.

## Genel Bakış

Trial Balance Extractor, Excel ve PDF dosyalarından mizan bilgilerini çıkarmak için kullanılan bir FastAPI uygulamasıdır. Tesseract OCR ve çeşitli veri işleme kütüphanelerini kullanır.

## Ön Gereksinimler

- Kubernetes cluster (1.20+)
- kubectl CLI tool
- Docker registry erişimi

## 1. Docker Image Build ve Push

```bash
# Docker image'ı build edin ve kendi registry'nize push edin
docker build -t your-registry.com/trial-balance-extractor:latest .
```

## 2. Konfigürasyon Düzenleme

### Deployment Image Güncellemesi
`k8s/deployment.yaml` dosyasındaki `your-registry.com/trial-balance-extractor:latest` kısmını kendi image adresinizle değiştirin.

## 3. Deployment

```bash
cd k8s/

# Tüm kaynakları uygula
kubectl apply -f .
```

## 4. Verification

```bash
# Pod durumunu kontrol et
kubectl get pods

# Service durumunu kontrol et
kubectl get svc

# Logları kontrol et
kubectl logs -f deployment/trial-balance-extractor

# Health check
kubectl port-forward svc/trial-balance-service 8080:8000
curl http://localhost:8080/health
```

## 5. Scaling (İsteğe Bağlı)

```bash
# Replica sayısını değiştir
kubectl scale deployment trial-balance-extractor --replicas=3
```

## 6. Troubleshooting

```bash
# Pod durumunu detaylı kontrol et
kubectl describe pod <pod-name>

# Önceki container logları
kubectl logs <pod-name> --previous
```

## Notlar

- LoadBalancer service kullanılıyor, external IP alacaktır
- Resource limits tanımlı: 512Mi-1Gi RAM, 250m-1000m CPU
- Health check endpoint: `/health`
- Database bağlantısı için secrets kullanılıyor

Bu deployment basit ve temel ihtiyaçları karşılayacak şekilde tasarlanmıştır.