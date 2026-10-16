# SpyDevDet

Android 11 ve üzeri cihazlarda ve Windows bilgisayarlarda, kullanıcının bağlı
olduğu yerel ağdaki cihazları keşfetmeyi ve bulunan kanıtlara göre açıklanabilir
bir inceleme/risk sonucu üretmeyi amaçlayan Flutter projesi.

Uygulama bir cihazın "casus" olduğunu kesin olarak iddia etmez. Yalnızca ağda
gözlemlenebilen IP, cihaz adı, servis, port ve benzeri bulguları kullanıcıya
açıklar.

## İlk hedef

İlk teslimat Android 11+ ve Windows için, ön planda ve kullanıcı tarafından
başlatılan bir yerel ağ taramasıdır. Hız testi ve Bluetooth ilk MVP'nin
dışındadır; kamera keşfi güvenli ONVIF/WS-Discovery duyurularıyla sınırlıdır.

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
- TCP, erişilebilirlik, mDNS, SSDP ve ONVIF/WS-Discovery keşifleri birbirini
  beklemeden paralel çalışır; ilerleme göstergesi bütün yöntemlerin durumunu
  hesaba katar.
- mDNS ve SSDP üzerinden yaygın yerel servis duyuruları dinlenir. SSDP'nin
  bildirdiği konum adreslerinden içerik indirilmez.
- Erişilebildiği platformlarda IP komşu tablosundaki geçerli kayıtlar hem cihaz
  keşfi hem de MAC zenginleştirmesi için kullanılır. Android 10 ve üzerinin
  `/proc/net` kısıtı nedeniyle MAC tablosu okunamazsa durum açıkça
  "edinilemedi" olarak gösterilir.
- IEEE MA-L, MA-M, MA-S ve IAB genel kayıtlarından geliştirme sırasında
  üretilen çevrimdışı OUI asset'i 24, 28 ve 36 bit en uzun prefix eşleşmesiyle
  üretici adını gösterebilir. Yerel/rastgele MAC adreslerinde üretici tahmin
  edilmez.
- ONVIF keşfi yalnız sınırlı WS-Discovery Probe mesajları gönderir ve
  ProbeMatch duyurularını ayrıştırır; kullanıcı adı/parola denemez, cihaz
  ayarlarını değiştirmez ve duyurulan servis adreslerinden içerik indirmez.
- Tanılama ekranı her yöntemin süresini, istek ve yanıt sayaçlarını, kabul
  edilmeyen yanıtları, multicast durumunu ve kullanılabilirlik nedenini
  gösterir. Bu toplu ölçümler tarama geçmişinde de saklanır.
- Gözlemlenen port ve duyurular merkezi servis kataloğuyla açıklanır. Portun
  açık olması tek başına tehlike veya kamera kanıtı sayılmaz.
- Yönlendirici, yazıcı, medya cihazı ve kamera adayı sınıfları gözlemlenen ağ
  kanıtlarıyla ve güven seviyesiyle birlikte gösterilir.
- Yeni cihaz, IP tabanlı zayıf kimlik ve kamera servisi gibi bulgular ayrı bir
  açıklanabilir inceleme durumunda özetlenir. Bu durum casusluk hükmü değildir.
- Erişilebilirlik, TCP, mDNS, SSDP, ONVIF ve MAC zenginleştirme aşamalarının
  başarı, hata, süre ve cihaz sayıları ayrı ayrı raporlanır; tek yöntemin
  kullanılamaması taramayı çökertmez.
- Tamamlanan taramalar Android ve Windows'ta yerel SQLite veritabanına kaydedilir.
  Veriler bir sunucuya veya bulut hesabına gönderilmez.
- Cihaz kimliği için IP yerine öncelikle genel MAC, ardından ONVIF endpoint,
  SSDP ve ağ kapsamındaki mDNS kimlikleri kullanılır. Güçlü kimlik yoksa ağ ve
  IP tabanlı düşük güvenli eşleştirmeye dönülür.
- Kullanıcı cihazı bilinen olarak işaretleyebilir, özel ad ve not ekleyebilir.
  Sonraki taramalarda yeni, daha önce görülen ve bilinen cihazlar ayrılır.
- TCP, mDNS, SSDP ve ONVIF aşamalarıyla birlikte erişilebilirlik veya komşu
  tablosu yöntemlerinden en az biri tamamlandığında önceki taramada olup bu taramada
  görülmeyen cihazlar listelenir. Tarama geçmişi kullanıcı tarafından
  tek tek veya topluca silinebilir; ayrıca bilinen cihaz profilleri, özel adlar
  ve notlar dahil bütün yerel veriler de temizlenebilir.

Bu yöntemlerin hiçbiri bütün cihazları bulmayı veya bir cihazın amacını kesin
olarak belirlemeyi garanti etmez. Özellikle "kamera adayı" etiketi, cihazın
gizli ya da kötü amaçlı olduğu anlamına gelmez.

## OUI verisini güncelleme

Uygulama OUI sorgusu için çalışma sırasında internete bağlanmaz. Geliştirme
makinesinde resmî IEEE genel kayıtlarından yeni bir çevrimdışı snapshot üretmek
için:

```powershell
dart run tool/update_oui_registry.dart
```

Kaynak ve veri kullanım notları `assets/data/README.md` dosyasındadır.
