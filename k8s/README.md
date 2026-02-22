# Kubernetes Deployment Files

Bu klasör Financial Analysis uygulamasının Kubernetes'e deploy edilmesi için gerekli dosyaları içerir.

## Dosyalar

- `configmap.yaml` - Uygulama konfigürasyonu (API ayarları)
- `deployment.yaml` - Ana uygulama deployment tanımı
- `service.yaml` - LoadBalancer service (external access)

## Deployment Adımları

1. Image'ı build edin ve registry'nize push edin
2. `deployment.yaml`'da image adresini kendi registry'nizle değiştirin
3. `kubectl apply -f .` komutu ile deploy edin

## Doğrulama

```bash
kubectl get pods
kubectl get svc
kubectl logs -f deployment/financial-analysis
```

LoadBalancer service external IP alacak ve uygulama 8000 portunda erişilebilir olacaktır.