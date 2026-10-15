# SpyDevDet

Android 11 ve üzeri cihazlarda ve Windows bilgisayarlarda, kullanıcının bağlı
olduğu yerel ağdaki cihazları keşfetmeyi ve bulunan kanıtlara göre açıklanabilir
bir inceleme/risk sonucu üretmeyi amaçlayan Flutter projesi.

Uygulama bir cihazın "casus" olduğunu kesin olarak iddia etmez. Yalnızca ağda
gözlemlenebilen IP, cihaz adı, servis, port ve benzeri bulguları kullanıcıya
açıklar.

## İlk hedef

İlk teslimat Android 11+ ve Windows için, ön planda ve kullanıcı tarafından
başlatılan bir yerel ağ taramasıdır. Hız testi, Bluetooth ve gelişmiş kamera
keşfi ilk MVP'nin dışındadır.

## Mevcut durum

- Android'de etkin Wi-Fi bağlantısının; Windows'ta etkin Wi-Fi veya Ethernet
  bağlantısının yerel IPv4 adresi, prefix değeri ve ağ geçidi işletim sisteminin
  yerel API'lerinden alınır.
- Yalnızca RFC1918 özel adres aralıkları taranır.
- Tarama en fazla 254 uzak adres ve sekiz yaygın TCP portuyla sınırlıdır.
- Android'de yerel adreslere işletim sisteminin ICMP/TCP tabanlı erişilebilirlik
  kontrolü uygulanır. Açık bir servis portu olmasa da yanıt veren cihazlar
  gözlemlenebilir; taramayı çalıştıran telefon ayrıca "Bu cihaz" olarak gösterilir.
- Mobil ağ ve algılanan VPN bağlantıları üzerinden tarama engellenir.
- TCP bağlantısı kurulduğunda socket hemen kapatılır; kimlik doğrulama veya veri
  gönderme işlemi yapılmaz.
- mDNS ve SSDP üzerinden yaygın yerel servis duyuruları dinlenir. SSDP'nin
  bildirdiği konum adreslerinden içerik indirilmez.
- Erişilebildiği platformlarda IP komşu tablosundaki geçerli kayıtlar hem cihaz
  keşfi hem de MAC zenginleştirmesi için kullanılır. Android 10 ve üzerinin
  `/proc/net` kısıtı nedeniyle MAC tablosu okunamazsa durum açıkça
  "edinilemedi" olarak gösterilir.
- Küçük ve çevrimdışı bir OUI eşlemesi bilinen birkaç üreticiyi gösterebilir;
  eşleşme yoksa üretici tahmin edilmez ve "Bilinmiyor" kalır.
- Yönlendirici, yazıcı, medya cihazı ve kamera adayı sınıfları gözlemlenen ağ
  kanıtlarıyla ve güven seviyesiyle birlikte gösterilir.
- Erişilebilirlik, TCP, mDNS, SSDP ve MAC zenginleştirme aşamalarının başarı,
  hata, süre ve cihaz sayıları ayrı ayrı raporlanır; tek yöntemin
  kullanılamaması taramayı çökertmez.
- Tamamlanan taramalar Android ve Windows'ta yerel SQLite veritabanına kaydedilir.
  Veriler bir sunucuya veya bulut hesabına gönderilmez.
- Cihaz kimliği için IP yerine öncelikle genel MAC, ardından SSDP ve mDNS
  kimlikleri kullanılır. Güçlü kimlik yoksa ağ ve IP tabanlı düşük güvenli
  eşleştirmeye dönülür.
- Kullanıcı cihazı bilinen olarak işaretleyebilir, özel ad ve not ekleyebilir.
  Sonraki taramalarda yeni, daha önce görülen ve bilinen cihazlar ayrılır.
- Yalnızca keşif yöntemleri eksiksiz tamamlandığında önceki taramada olup bu
  taramada görülmeyen cihazlar listelenir. Tarama geçmişi kullanıcı tarafından
  tek tek veya topluca silinebilir; bilinen cihaz profilleri korunur.

Bu yöntemlerin hiçbiri bütün cihazları bulmayı veya bir cihazın amacını kesin
olarak belirlemeyi garanti etmez. Özellikle "kamera adayı" etiketi, cihazın
gizli ya da kötü amaçlı olduğu anlamına gelmez.
