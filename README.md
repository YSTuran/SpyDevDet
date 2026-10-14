# SpyDevDet

Android 11 ve üzeri cihazlarda, kullanıcının bağlı olduğu yerel ağdaki cihazları
keşfetmeyi ve bulunan kanıtlara göre açıklanabilir bir inceleme/risk sonucu
üretmeyi amaçlayan Flutter projesi.

Uygulama bir cihazın "casus" olduğunu kesin olarak iddia etmez. Yalnızca ağda
gözlemlenebilen IP, cihaz adı, servis, port ve benzeri bulguları kullanıcıya
açıklar.

## İlk hedef

İlk teslimat Android 11+ için, ön planda ve kullanıcı tarafından başlatılan bir
yerel ağ taramasıdır. Windows, hız testi, Bluetooth ve gelişmiş kamera keşfi ilk
MVP'nin dışındadır.

## Mevcut durum

- Etkin Wi-Fi bağlantısının yerel IPv4 adresi ve prefix değeri Android'den alınır.
- Yalnızca RFC1918 özel adres aralıkları taranır.
- Tarama en fazla 254 uzak adres ve sekiz yaygın TCP portuyla sınırlıdır.
- Mobil ağ ve VPN üzerinden tarama engellenir.
- TCP bağlantısı kurulduğunda socket hemen kapatılır; kimlik doğrulama veya veri
  gönderme işlemi yapılmaz.

Bu temel TCP taraması bütün cihazları bulmayı garanti etmez. mDNS ve SSDP keşfi
sonraki geliştirme aşamalarında eklenecektir.
