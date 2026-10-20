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
- Hızlı mod erişilebilirlik, komşu tablosu ve kamera odaklı beş TCP portunu
  kontrol eder. Ayrıntılı mod sekiz TCP portunun yanı sıra mDNS, SSDP ve ONVIF
  duyurularını da çalıştırır. Atlanan yöntemler tanılamada açıkça gösterilir.
- Android ve Windows'ta yerel adreslere işletim sisteminin erişilebilirlik
  kontrolü uygulanır. Windows tarafında sınırlı ICMP Echo kullanılır. Açık bir
  servis portu olmasa da yanıt veren cihazlar gözlemlenebilir; taramayı
  çalıştıran telefon veya bilgisayar ayrıca "Bu cihaz" olarak gösterilir.
- Mobil ağ ve algılanan VPN bağlantıları üzerinden tarama engellenir.
- TCP bağlantısı kurulduğunda socket hemen kapatılır; kimlik doğrulama veya veri
  gönderme işlemi yapılmaz.
- TCP, erişilebilirlik, mDNS, SSDP ve ONVIF/WS-Discovery keşifleri birbirini
  beklemeden paralel çalışır; ilerleme göstergesi bütün yöntemlerin durumunu
  hesaba katar.
- mDNS üzerinden yaygın servisler ve DNS-SD servis türü duyuruları keşfedilir.
  Yalnız model/üretici gibi sınırlı TXT alanları temizlenerek kullanılır. mDNS
  sorguları sınırlı eşzamanlılıkla çalıştırılır; SSDP ve ONVIF yanıtları sayısal
  ve boyutsal sınırlarla işlenir. Bildirilen konum adreslerinden içerik
  indirilmez.
- Erişilebildiği platformlarda IP komşu tablosundaki geçerli kayıtlar hem cihaz
  keşfi hem de MAC zenginleştirmesi için kullanılır. Android 10 ve üzerinin
  `/proc/net` kısıtı nedeniyle MAC tablosu okunamadığında bunun bir izin hatası
  olmadığı açıkça belirtilir; cihazlar servis kimliği ve IP kanıtlarıyla
  izlenmeye devam eder. Windows'ta etkin ağ bağdaştırıcısının fiziksel adresi
  "Bu cihaz" kaydına eklenir.
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
  IP tabanlı düşük güvenli eşleştirmeye dönülür. Sonradan güçlü kimlik bulunan
  cihazlar kimlik takma adlarıyla önceki profiline bağlanır; aynı IP'yi alan
  farklı bir güçlü kimlik eski profili devralmaz.
- Alt ağ ve ağ geçidi adresinden oluşan temel ağ kimliği her taramada
  kullanılabilir. Ağ geçidinin MAC adresi veya güvenilir SSDP/ONVIF servis
  kimliği edinilebildiğinde buna güçlü bir kimlik takma adı eklenir; güçlü kanıt
  bulunamazsa profil sınırlı kimlik olarak işaretlenir. MAC bilgisinin geçici
  olarak alınamaması aynı ağın geçmişini bölmez, aynı adresleri kullanan farklı
  ağ geçitleri güçlü kanıt bulunduğunda ayrılır.
  Tarama sırasında yerel IP, bağdaştırıcı veya ağ geçidi değişirse sonuçlar
  eski ağın geçmişine yazılmadan tarama durdurulur. Tamamlanmış bir taramadan
  geç dönen ağ kontrolü kaydedilmiş sonucu geçersiz kılamaz. Uygulama arka
  plana geçtiğinde de devam eden tarama güvenli biçimde iptal edilir.
- Kullanıcı cihazı bilinen olarak işaretleyebilir, özel ad ve not ekleyebilir.
  Ayrıca cihazın kendisine/evine ait olduğunu belirtebilir ve otomatik cihaz
  türünü düzeltebilir. Otomatik tahmin kaybedilmeden kullanıcı düzeltmesi ayrı
  saklanır. Sonraki taramalarda yeni, daha önce görülen ve bilinen cihazlar ayrılır.
- Cihazlar ad, IP, MAC, üretici ve servis bilgisiyle aranabilir; tanınma,
  kategori, üretici, MAC ve inceleme durumuna göre filtrelenip sıralanabilir.
- İnceleme sonucu toplam puanla birlikte puana katkı yapan her bulguyu gösterir.
  Bir cihazın görünmemesi halinde uyku, güvenlik duvarı, misafir ağı, istemci
  izolasyonu ve kullanılamayan keşif yöntemleri gibi olası nedenler açıklanır.
- Ağlar ayrı yerel profillerde tutulur, kullanıcı tarafından adlandırılabilir
  ve her ağın tarama geçmişi ayrıca görüntülenebilir.
- Mobil görünümde Material 3 alt gezinme çubuğu, geniş Windows görünümünde yan
  gezinme çubuğu kullanılır. Varsayılan Aydınlık + Material görünümünün yanında
  karanlık/sistem modu ve Okyanus, Zümrüt, Menekşe, Kehribar renk paletleri
  seçilebilir. Görünüm tercihleri yalnız cihazda saklanır.
- Ayrıntılı keşif yöntemleri başarıyla tamamlandığında önceki taramada olup bu
  taramada görülmeyen cihazlar listelenir. Android'in beklenen komşu tablosu
  kısıtı ayrıca raporlanır ancak diğer yöntemler tamamsa karşılaştırmayı tek
  başına engellemez. Hızlı veya gerçekten kısmi tarama hatalı "görülmedi"
  sonucu üretmez. Tarama geçmişi kullanıcı tarafından
  tek tek veya topluca silinebilir; ayrıca bilinen cihaz profilleri, özel adlar
  ve notlar dahil bütün yerel tarama verileri de temizlenebilir. Görünüm
  tercihleri bu işlemden etkilenmez. Veritabanının sınırsız büyümemesi için her
  ağın en yeni 100 taraması saklanır; cihaz profilleri bu temizlikten etkilenmez.

Bu yöntemlerin hiçbiri bütün cihazları bulmayı veya bir cihazın amacını kesin
olarak belirlemeyi garanti etmez. Özellikle "kamera adayı" etiketi, cihazın
gizli ya da kötü amaçlı olduğu anlamına gelmez.

## Gerçek cihaz kontrol listesi

Her önemli APK kontrol noktasında aynı Wi-Fi ağı için en az iki ardışık tarama
yapılması önerilir:

1. Modem arayüzündeki bağlı cihaz listesini not et.
2. Telefon, bilgisayar ve varsa televizyon/yazıcı gibi cihazlar açıkken tara.
3. İkinci taramada cihazların "daha önce görüldü" durumunu kontrol et.
4. Bir cihazın IP adresi değiştiğinde MAC veya servis kimliğiyle aynı profile
   bağlanıp bağlanmadığını kontrol et.
5. Tarama sürerken Wi-Fi'yi kapat veya başka ağa geç; sonucun kaydedilmediğini
   doğrula.
6. Tanılama ekranındaki gerçek TCP deneme, yanıt ve zaman aşımı sayılarını
   kaydet. Görünmeyen cihazların uyku, güvenlik duvarı veya istemci izolasyonu
   nedeniyle yanıt vermeyebileceğini göz önünde bulundur.
7. Aynı ağı önce hızlı, sonra ayrıntılı modda tara; ayrıntılı modda mDNS, SSDP
   ve ONVIF aşamalarının çalıştığını kontrol et.
8. Ağ profiline bir ad, bir cihaza sahiplik/kategori düzeltmesi ekle; uygulamayı
   yeniden açtıktan ve tekrar taradıktan sonra bilgilerin korunduğunu doğrula.

## OUI verisini güncelleme

Uygulama OUI sorgusu için çalışma sırasında internete bağlanmaz. Geliştirme
makinesinde resmî IEEE genel kayıtlarından yeni bir çevrimdışı snapshot üretmek
için:

```powershell
dart run tool/update_oui_registry.dart
```

Kaynak ve veri kullanım notları `assets/data/README.md` dosyasındadır.

## Android imzalama

Yerel kontrol APK'ları `android/key.properties` bulunmadığında geliştirme
anahtarıyla üretilebilir. Başka kullanıcılara kalıcı bir APK vermeden önce
`android/key.properties.example` örneğini `android/key.properties` adıyla
kopyalayıp yalnız sana ait bir JKS anahtarı tanımla. Gerçek parola ve JKS
dosyaları Git tarafından yok sayılır; bu dosyaları depoya ekleme veya paylaşma.
