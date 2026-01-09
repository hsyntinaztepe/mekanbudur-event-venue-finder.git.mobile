# MekanBudur - Etkinlik ve Hizmet Pazar Yeri

Mikroservis mimarisi ve Flutter mobil uygulama ile gelistirilmis etkinlik pazar yeri platformu. Kullanicilar etkinlik ilanlari olusturabilir, tedarikciler (vendor) bu ilanlara teklif verebilir.

## Proje Hakkinda

MekanBudur, etkinlik sahipleri ile hizmet saglayicilari bir araya getiren bir pazar yeri uygulamasidir. Platform iki ana kullanici rolune sahiptir:

- **Kullanici (User):** Etkinlik ilanlari olusturur, gelen teklifleri degerlendirir ve kabul eder.
- **Tedarikci (Vendor):** Acik ilanlari inceler ve hizmet verebilecegi ilanlara teklif gonderir.

## Teknolojiler

### Backend
- .NET 8.0 (Minimal API)
- Entity Framework Core 8.0 (Code First)
- PostgreSQL 16
- JWT Authentication

### Mobil Uygulama
- Flutter 3.x
- Provider (State Management)
- Dio (HTTP Client)
- GoRouter (Navigation)
- flutter_map + latlong2 (Harita)

### Altyapi
- Docker ve Docker Compose
- pgAdmin 4

## Proje Yapisi

```
mekanbudur/
|
|-- src/
|   |-- Api/                          # Ana API servisi (.NET 8)
|   |   |-- Data/
|   |   |   |-- AppDbContext.cs       # Entity Framework DbContext
|   |   |-- DTOs/
|   |   |   |-- AuthDtos.cs           # Kimlik dogrulama DTO'lari
|   |   |   |-- BidDtos.cs            # Teklif DTO'lari
|   |   |   |-- ListingDtos.cs        # Ilan DTO'lari
|   |   |   |-- VendorDtos.cs         # Tedarikci DTO'lari
|   |   |-- Models/
|   |   |   |-- User.cs               # Kullanici modeli
|   |   |   |-- EventListing.cs       # Ilan modeli
|   |   |   |-- Bid.cs                # Teklif modeli
|   |   |   |-- VendorProfile.cs      # Tedarikci profili
|   |   |   |-- ServiceCategory.cs    # Hizmet kategorisi
|   |   |-- Services/
|   |   |   |-- JwtTokenService.cs    # JWT token uretimi
|   |   |   |-- GeoClient.cs          # Geo servisi istemcisi
|   |   |-- Program.cs                # API endpoint tanimlari
|   |   |-- Dockerfile
|   |
|   |-- Geo/                          # Konum servisi (.NET 8)
|   |   |-- Data/
|   |   |   |-- GeoDbContext.cs
|   |   |-- Models/
|   |   |   |-- Place.cs              # Konum modeli
|   |   |-- Program.cs                # Geo API endpoint'leri
|   |   |-- Dockerfile
|   |
|   |-- mobile/                       # Flutter mobil uygulama
|       |-- lib/
|       |   |-- core/
|       |   |   |-- api_client.dart   # Dio HTTP istemcisi
|       |   |   |-- router.dart       # GoRouter yapilandirmasi
|       |   |-- data/
|       |   |   |-- models/           # Veri modelleri
|       |   |   |-- services/         # API servisleri
|       |   |-- presentation/
|       |   |   |-- providers/        # State yonetimi
|       |   |   |-- screens/          # Ekranlar
|       |   |       |-- auth/         # Giris/Kayit ekranlari
|       |   |       |-- listing/      # Ilan ekranlari
|       |   |       |-- vendor/       # Tedarikci ekranlari
|       |   |-- main.dart
|       |-- pubspec.yaml
|
|-- docker-compose.yml                # Docker servis tanimlari
|-- README.md
```

## Kurulum

### Gereksinimler

- Docker ve Docker Compose
- Flutter SDK 3.x (mobil uygulama icin)
- Android Studio veya VS Code

### Backend Servisleri

1. Projeyi klonlayin:
```bash
git clone https://github.com/hsyntinaztepe/mekanbudur-event-venue-finder.git.mobile.git
cd mekanbudur-event-venue-finder.git.mobile
```

2. Docker ile servisleri baslatin:
```bash
docker compose up --build
```

3. Servislerin hazir olmasini bekleyin (ilk baslatmada 1-2 dakika surebilir).

### Mobil Uygulama

1. Flutter bagimliliklerini yukleyin:
```bash
cd src/mobile
flutter pub get
```

2. Uygulamayi calistirin:
```bash
flutter run
```

Not: Android emulatorunde API'ye baglanmak icin `api_client.dart` dosyasindaki base URL `http://10.0.2.2:8084/api` olarak ayarlidir.

## Servis Adresleri

| Servis | Adres | Aciklama |
|--------|-------|----------|
| API | http://localhost:8084 | Ana API servisi |
| API Swagger | http://localhost:8084/swagger | API dokumantasyonu |
| Geo API | http://localhost:8083 | Konum servisi |
| pgAdmin | http://localhost:5051 | Veritabani yonetimi |
| PostgreSQL (Ana) | localhost:5434 | Ana veritabani |
| PostgreSQL (Geo) | localhost:5436 | Geo veritabani |

## Demo Hesaplar

Proje ilk baslatildiginda otomatik olarak demo hesaplar olusturulur:

| Rol | E-posta | Sifre |
|-----|---------|-------|
| Kullanici | user@demo.com | Pass123* |
| Tedarikci | vendor@demo.com | Pass123* |

## API Endpoint'leri

### Kimlik Dogrulama
- `POST /api/auth/register` - Yeni kullanici kaydi
- `POST /api/auth/login` - Kullanici girisi

### Kategoriler
- `GET /api/categories` - Hizmet kategorilerini listele

### Ilanlar
- `GET /api/listings` - Tum ilanlari listele
- `GET /api/listings/{id}` - Ilan detayi
- `GET /api/listings/mine` - Kullanicinin kendi ilanlari (Auth: User)
- `POST /api/listings` - Yeni ilan olustur (Auth: User)
- `PATCH /api/listings/{id}/visibility` - Ilan gorunurlugunu guncelle

### Teklifler
- `POST /api/bids` - Teklif ver (Auth: Vendor)
- `GET /api/bids/mine` - Tedarikci teklifleri (Auth: Vendor)
- `GET /api/listings/{id}/bids` - Ilana gelen teklifler (Auth: Ilan sahibi)
- `POST /api/bids/{id}/accept` - Teklif kabul et (Auth: User)

### Konum (Geo)
- `POST /api/places/upsert` - Konum ekle/guncelle
- `GET /api/places/by-ref` - Referansa gore konum getir

## Veritabani Yapisi

### Ana Veritabani (evently)

**Users**
- Id, Email, PasswordHash, DisplayName, Role (User/Vendor)

**VendorProfiles**
- Id, UserId, CompanyName, ServiceCategoriesCsv

**ServiceCategories**
- Id, Name

**EventListings**
- Id, Title, Description, EventDate, Location, Status, Visibility, CreatedByUserId

**EventListingItems**
- Id, EventListingId, ServiceCategoryId, Budget, Status

**Bids**
- Id, EventListingId, VendorId, TotalAmount, Message, Status

**BidItems**
- Id, BidId, EventListingItemId, Amount

### Geo Veritabani (evently_geo)

**Places**
- Id, RefType (Listing/Vendor), RefId, Latitude, Longitude, Radius, AddressLabel

## Ozellikler

### Kullanici Ozellikleri
- Kayit olma ve giris yapma
- Etkinlik ilani olusturma (harita uzerinden konum secimi)
- Ilan gorunurluk yonetimi (yayinla/gizle/kaldir)
- Gelen teklifleri inceleme ve kabul etme

### Tedarikci Ozellikleri
- Tedarikci olarak kayit olma
- Acik ilanlari goruntuleme (Pazar Alani)
- Ilanlara teklif verme
- Kendi tekliflerini takip etme
- Profil yonetimi

### Harita Entegrasyonu
- Ilan olustururken haritadan konum secimi
- Kapsam yaricapi belirleme
- Ilan detaylarinda harita gorunumu

## Gelistirme

### Kod Yapilandirmasi

Backend servisleri .NET 8 Minimal API kullanir. Tum endpoint'ler `Program.cs` dosyalarinda tanimlidir.

Flutter uygulamasi Provider pattern ile state yonetimi yapar. Ekranlar `presentation/screens` altinda, API servisleri `data/services` altindadir.

### Veritabani

Entity Framework Core Code First yaklasimi kullanilir. Ilk calistirmada `EnsureCreated()` ile sema olusturulur.

### Docker

Tum servisler Docker container'larinda calisir. `docker-compose.yml` dosyasi servis bagimliliklerini ve health check'leri tanimlar.

## pgAdmin Kullanimi

pgAdmin'e http://localhost:5050 adresinden erisin.

Giris bilgileri:
- E-posta: admin@mekanbudur.com
- Sifre: admin

Veritabani baglantisi icin:
- Host: db (ana) veya geodb (geo)
- Port: 5432
- Kullanici: postgres
- Sifre: postgres

## Lisans

Bu proje egitim amacli gelistirilmistir.
