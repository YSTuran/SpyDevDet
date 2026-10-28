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
- Tarama en fazla 254 uzak adres ve on yaygın TCP portuyla sınırlıdır.
- Hızlı mod erişilebilirlik, komşu tablosu ve kamera odaklı beş TCP portunu
  kontrol eder. Ayrıntılı mod on TCP portunun yanı sıra mDNS, SSDP,
  WS-Discovery ve NetBIOS keşiflerini de çalıştırır. Atlanan yöntemler
  tanılamada açıkça gösterilir.
- Tarama başlamadan önce etkin bağlantı türü, yerel IP/prefix, alt ağ, ağ
  geçidi, VPN durumu, seçilen mod, planlanan adres aralığı ve hedef sayısı
  gösterilir. Android'in MAC/üretici bilgisine ilişkin platform kısıtı bu
  özette ayrıca açıklanır.
- Android ve Windows'ta yerel adreslere işletim sisteminin erişilebilirlik
  kontrolü uygulanır. Windows tarafında sınırlı ICMP Echo kullanılır. Açık bir
  servis portu olmasa da yanıt veren cihazlar gözlemlenebilir; taramayı
  çalıştıran telefon veya bilgisayar ayrıca "Bu cihaz" olarak gösterilir.
- Mobil ağ ve algılanan VPN bağlantıları üzerinden tarama engellenir.
- TCP bağlantısı kurulduğunda socket hemen kapatılır; kimlik doğrulama veya veri
  gönderme işlemi yapılmaz.
- Ayrıntılı tarama Windows bilgisayarlarını görünür kılmaya yardımcı olmak için
  SMB (TCP 445) ve Uzak Masaüstü (TCP 3389) portlarını da sınırlı bağlantı
  denemesiyle kontrol eder. Uygulama paylaşımları açmaz, dosya okumaz ve uzak
  oturum başlatmaz.
- TCP, erişilebilirlik, mDNS, SSDP, WS-Discovery ve NetBIOS keşifleri birbirini
  beklemeden paralel çalışır; ilerleme göstergesi bütün yöntemlerin durumunu
  hesaba katar. WS-Discovery ile NetBIOS ayrı durum, süre ve sayaçlarla
  raporlanır; eski birleşik geçmiş kayıtları geriye dönük olarak okunur.
- mDNS üzerinden yaygın servisler ve DNS-SD servis türü duyuruları keşfedilir.
  Yalnız model/üretici gibi sınırlı TXT alanları temizlenerek kullanılır. mDNS
  sorguları sınırlı eşzamanlılıkla çalıştırılır; SSDP, WS-Discovery ve NetBIOS
  yanıtları sayısal ve boyutsal sınırlarla işlenir. Bildirilen konum
  adreslerinden içerik
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
- WS-Discovery keşfi sınırlı ONVIF video ve genel cihaz Probe mesajları gönderir
  ve yalnız eşleşen ProbeMatch duyurularını ayrıştırır. Ayrıntılı mod ayrıca
  yerel yayın adresine iki sınırlı NetBIOS Node Status sorgusu göndererek
  yanıtlayan Windows cihazlarının adını kullanabilir. Kullanıcı adı/parola
  denemez, paylaşım açmaz, cihaz ayarlarını değiştirmez ve duyurulan servis
  adreslerinden içerik indirmez.
- Tanılama ekranı her yöntemin süresini, istek ve yanıt sayaçlarını, kabul
  edilmeyen yanıtları, multicast durumunu ve kullanılabilirlik nedenini
  gösterir. Bu toplu ölçümler tarama geçmişinde de saklanır. Kullanıcı ayrıca
  bu ekrandan IP adresleri maskelenmiş, MAC ve cihaz kimlikleri çıkarılmış bir
  JSON tanılama paketi oluşturabilir; paket yalnız kullanıcı isteğiyle
  kaydedilir veya paylaşılır ve otomatik yüklenmez.
- Gözlemlenen port ve duyurular merkezi servis kataloğuyla açıklanır. Portun
  açık olması tek başına tehlike veya kamera kanıtı sayılmaz.
- Yönlendirici, yazıcı, medya cihazı ve kamera adayı sınıfları gözlemlenen ağ
  kanıtlarıyla ve güven seviyesiyle birlikte gösterilir.
- Yeni cihaz, IP tabanlı zayıf kimlik ve kamera servisi gibi bulgular ayrı bir
  açıklanabilir inceleme durumunda özetlenir. Bu durum casusluk hükmü değildir.
- Erişilebilirlik, TCP, mDNS, SSDP, WS-Discovery, NetBIOS ve MAC zenginleştirme aşamalarının
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
  kullanılabilir. Ağ geçidinin genel MAC adresi edinilebildiğinde buna güçlü
  bir kimlik takma adı eklenir; SSDP/ONVIF servis kimlikleri tek başına güçlü
  ağ kanıtı sayılmaz. Güçlü kanıt bulunamazsa profil sınırlı kimlik olarak
  işaretlenir. MAC bilgisinin geçici olarak alınamaması aynı ağın geçmişini
  bölmez, aynı adresleri kullanan farklı ağ geçitleri güçlü kanıt bulunduğunda
  ayrılır.
  Tarama sırasında yerel IP, bağdaştırıcı veya ağ geçidi değişirse sonuçlar
  eski ağın geçmişine yazılmadan tarama durdurulur. Tamamlanmış bir taramadan
  geç dönen ağ kontrolü kaydedilmiş sonucu geçersiz kılamaz. Uygulama arka
  plana geçtiğinde de devam eden tarama güvenli biçimde iptal edilir.
- Kullanıcı cihazı bilinen olarak işaretleyebilir, özel ad ve not ekleyebilir.
  Ayrıca cihazın kendisine/evine ait olduğunu belirtebilir ve otomatik cihaz
  türünü düzeltebilir. Otomatik tahmin kaybedilmeden kullanıcı düzeltmesi ayrı
  saklanır. Sonraki taramalarda yeni, daha önce görülen ve bilinen cihazlar ayrılır.
- Cihaz profilleri ayrı Cihazlar ekranında aranabilir, filtrelenebilir,
  düzenlenebilir veya unutulabilir. Bir profili unutmak geçmiş tarama
  oturumlarını silmez.
- Her cihaz profilinde ilk/son görülme, toplam gözlem sayısı, görüldüğü ve
  karşılaştırılabilir bir taramada görülmediği zamanlar gösterilir. Ardışık
  gözlemler arasındaki IP, servis, üretici, tür, güven ve kimlik kalitesi
  değişiklikleri zaman çizelgesinde açıklanır.
- Cihazlar ad, IP, MAC, üretici ve servis bilgisiyle aranabilir; tanınma,
  kategori, üretici, MAC ve inceleme durumuna göre filtrelenip sıralanabilir.
- İnceleme sonucu toplam puanla birlikte puana katkı yapan her bulguyu gösterir.
  Bir cihazın görünmemesi halinde uyku, güvenlik duvarı, misafir ağı, istemci
  izolasyonu ve kullanılamayan keşif yöntemleri gibi olası nedenler açıklanır.
- Ağlar ayrı yerel profillerde tutulur, kullanıcı tarafından adlandırılabilir
  ve her ağın tarama geçmişi ayrıca görüntülenebilir. Tek bir ağ profili ve
  geçmişi diğer ağlara veya cihaz notlarına dokunmadan silinebilir.
- Geçmiş ekranındaki istatistik görünümü son taramalardaki cihaz sayısı
  eğilimini, ortalama tarama süresini, yeni/görülmeyen cihaz kayıtlarını,
  bilinen-tanımlanmamış dağılımını ve en sık gözlemlenen cihazları yalnız yerel
  verilerden hesaplar. İstatistikler tüm ağlar veya seçilen tek ağ için
  filtrelenebilir; ağ profilinden ilgili istatistiklere doğrudan gidilebilir.
- TCP hedefleri sınırlı eşzamanlı hedef gruplarıyla taranır. Yanıt veren
  hedeflerde kalan kontroller daha kısa zaman aşımı kullanır; yaygın web ve
  Windows servisleri önceliklendirilir. Tarama ilerledikçe tahmini kalan süre
  kullanıcıya gösterilir.
- Mobil görünümde yuvarlatılmış Material 3 alt gezinme çubuğu, geniş Windows
  görünümünde markalı yan gezinme paneli kullanılır. Kartlar, formlar, düğmeler,
  iletişim pencereleri ve tarama eylem alanı ortak ve uyarlanabilir bir görsel
  sistem kullanır. Varsayılan Aydınlık + Material görünümünün yanında
  karanlık/sistem modu ve Okyanus, Zümrüt, Menekşe, Kehribar, Gül, Mercan,
  İndigo ve Grafit renk paletleri seçilebilir. Görünüm tercihleri yalnız cihazda
  saklanır.
- Android adaptif uygulama simgesi, aydınlık/karanlık açılış ekranı ve Windows
  çok boyutlu uygulama simgesi ortak SpyDevDet marka işaretini kullanır.
- Ayrıntılı keşif yöntemleri başarıyla tamamlandığında kullanıcı bir taramayı
  ağ referansı olarak seçebilir. Sonraki karşılaştırılabilir taramalarda
  eklenen ve görülmeyen cihazların yanı sıra IP, servis, üretici, otomatik tür,
  sınıflandırma güveni ve gözlemlenen kimlik kalitesi değişiklikleri gösterilir.
  "Uygulamada ilk kez görüldü" durumu, "referanstan sonra eklendi" durumundan
  ayrı tutulur. Sabit referans yoksa en son karşılaştırılabilir tarama geçici
  temel olarak kullanılır. Android'in beklenen komşu tablosu kısıtı ayrıca
  raporlanır ancak diğer yöntemler tamamsa karşılaştırmayı tek başına
  engellemez. Hızlı veya gerçekten kısmi tarama hatalı değişiklik sonucu
  üretmez. Tarama geçmişi kullanıcı tarafından
  tek tek veya topluca silinebilir; ayrıca bilinen cihaz profilleri, özel adlar
  ve notlar dahil bütün yerel tarama verileri de temizlenebilir. Görünüm
  tercihleri bu işlemden etkilenmez. Veritabanının sınırsız büyümemesi için her
  ağın en yeni 25, 50 veya 100 taramasının saklanması seçilebilir. Ağ referansı
  sınır içinde korunur; cihaz profilleri bu temizlikten etkilenmez.
- Her tarama yöntem sonuçlarına göre Tam kapsamlı, Sınırlı kapsamlı veya
  Karşılaştırmaya uygun değil şeklinde derecelendirilir. Android'in beklenen
  komşu tablosu kısıtı, diğer gerekli yöntemler tamamlandıysa kaliteyi tek
  başına düşürmez.
- Kullanıcı aynı ağdaki iki tam kapsamlı geçmiş taramayı seçerek referanstan
  bağımsız karşılaştırabilir. Farklı ağlar, hızlı taramalar ve gerçekten kısmi
  taramalar yanlış kayıp cihaz sonucu üretmemek için seçilemez.
- Geçmiş taramalar JSON, CSV veya okunabilir metin raporu olarak dışa
  aktarılabilir. Varsayılan gizlilik korumalı raporda IP/MAC adresleri
  maskelenir; özel cihaz adları, notlar, ağ kimliği ve kanıt tanımlayıcıları
  çıkarılır. Tam teknik rapor ayrıca kullanıcı onayı gerektirir.
- İlk açılış rehberi tarama modlarını, Android MAC sınırlamasını, referans
  karşılaştırmasını ve sonuçların sınırlarını açıklar. Rehber Ayarlar ekranından
  yeniden açılabilir ve tamamlanma tercihi yalnız cihazda saklanır.

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
   ile ayrı WS-Discovery ve NetBIOS aşamalarının çalıştığını kontrol et.
8. Ağ profiline bir ad, bir cihaza sahiplik/kategori düzeltmesi ekle; uygulamayı
   yeniden açtıktan ve tekrar taradıktan sonra bilgilerin korunduğunu doğrula.

### Erişilebilirlik ve ekran kontrolü

Widget testleri 360×800, 412×915, 800×600, 1280×720 ve 1920×1080 ekranlarda;
normal, %150 ve %200 metin ölçeklerinde kritik ekranları denetler. APK kontrol
noktalarında bunlara ek olarak telefonda şu manuel kontroller yapılmalıdır:

1. TalkBack'i açıp tarama modu, tarama durumu, ilerleme ve cihaz kartlarının
   anlamlı ve tek parça hâlinde okunduğunu kontrol et.
2. Yazı boyutunu en büyüğe yaklaştır; tarama ve tema seçeneklerinin dikey düzene
   geçtiğini, alt menünün kesilmediğini doğrula.
3. Windows'ta Tab ve Shift+Tab ile gezin; görünür odağın tüm etkileşimli
   kontrollere ulaştığını ve Enter/Boşluk ile çalıştığını doğrula.

## Sürekli entegrasyon

`.github/workflows/quality.yml`, `main` dalına gönderimlerde ve pull request'lerde
biçimlendirme, statik analiz, tüm testler, Android release APK ve kendi çalışma
zamanı dosyalarını içeren Windows release ZIP paketini doğrular. Android 11
(API 30) emülatörü minimum sürümde, Android 17 (API 37) emülatörü ise güncel
sürümde gerçek platform kanalını sınar. Windows işi gerçek masaüstü hedefinde
ana Tarama, Cihazlar, Ağlar ve Ayarlar bölümlerini gezen entegrasyon testini
çalıştırır. İş akışı elle veya `v` ile başlayan bir etiket üzerinden
çalıştırıldığında başarılı Android release APK ile Windows release ZIP ve
SHA-256 özeti 14 gün süreyle GitHub Actions artifact'i olarak saklanır. Telefon
kontrol noktalarında aşağıdaki yerel release APK da kullanılabilir.

Proje şu anda Android API 36'yı hedefler. Bu nedenle Android 17'de yerel ağ
erişimi mevcut `INTERNET` izniyle çalışmaya devam eder. Hedef SDK API 37'ye
yükseltilmeden önce `ACCESS_LOCAL_NETWORK` izni manifest'e eklenmeli, çalışma
anında istenmeli ve reddedilme/sonradan kaldırılma yolları arayüz ve entegrasyon
testleriyle ele alınmalıdır. İzin yalnız hedef SDK 37 geçişiyle birlikte
eklenmelidir; mevcut hedefte erken eklemek desteklenen cihazlarda gereksiz bir
izin akışı oluşturur.

Android yapılandırması Flutter 3.47.8 ile doğrulanan AGP 9.0.1, Gradle 9.1.0 ve
AGP'nin yerleşik Kotlin 2.3.20 çalışma zamanını kullanır. Uygulama modülü eski
`kotlin-android` eklentisi ve `kotlinOptions` bloğu yerine built-in Kotlin
yapılandırmasına geçirilmiştir. Flutter 3.47.8'in Gradle eklentisi yeni AGP DSL
geçişini tamamlayana kadar yalnız `android.newDsl=false` uyumluluk katmanı
korunur.

## OUI verisini güncelleme

Uygulama OUI sorgusu için çalışma sırasında internete bağlanmaz. Geliştirme
makinesinde resmî IEEE genel kayıtlarından yeni bir çevrimdışı snapshot üretmek
için:

```powershell
dart run tool/update_oui_registry.dart
```

Kaynak ve veri kullanım notları `assets/data/README.md` dosyasındadır.

## Yerel Android APK'sı

Proje mağaza dağıtımı veya AAB yayını hedeflemez. Telefon kontrolleri için
geliştirme anahtarıyla imzalanan yerel APK şu komutla üretilebilir:

```powershell
flutter build apk --release
```

Üretilen dosya `build/app/outputs/flutter-apk/app-release.apk` konumundadır.
Android sürümü, Galaxy A10 gibi eski Samsung/Exynos-Mali cihazlarda Impeller ve
yerel grafik sürücüsü etkileşiminden doğabilen açılış çökmelerini önlemek için
Skia çizim arka ucunu kullanır. Bu uyumluluk ayarı ağ keşfi ve veri saklama
işlevlerini değiştirmez.

## Windows release paketi

Windows çıktısı tek başına `spy_dev_det.exe` dosyasından oluşmaz; `Release`
klasöründeki DLL ve `data` içerikleriyle birlikte dağıtılmalıdır. Güncel kaynak
koddan sürümlü ZIP ve SHA-256 özeti üretmek için:

```powershell
powershell -ExecutionPolicy Bypass -File tool/package_windows_release.ps1
```

Paket ve özet `build/distributions` klasörüne yazılır. Betik önce Windows
release derlemesini oluşturur, ardından bütün çalışma zamanı dosyalarını aynı
arşive ekler.

## Performans ve dayanıklılık kontrolü

Otomatik test paketi tarama birleştirme hattını art arda çalıştıran
bir regresyon kontrolü ile devam eden taramanın iptal süresini sınayan bir
kontrol içerir. Bunlar gerçek ağ veya telefon performansının yerine geçmez.
Her APK kontrol noktasında Galaxy A10 üzerinde aşağıdaki değerler ayrıca
kaydedilmelidir:

| Kontrol | Kabul ölçütü | Ölçülen değer |
| --- | --- | --- |
| Temiz açılış | Çökme veya siyah ekranda kalma yok | Manuel |
| Beş ardışık hızlı tarama | Çökme ve kilitlenme yok | Manuel |
| Beş ardışık ayrıntılı tarama | Çökme ve kilitlenme yok | Manuel |
| Tarama iptali | Arayüz kısa sürede bekleme durumuna döner | Manuel |
| Arka plana alma | Devam eden tarama güvenle iptal edilir | Manuel |
| 100 kayıtla geçmiş | Ekran kullanılabilir kalır | Manuel |

Gerçek tarama süreleri ağdaki hedef ve güvenlik duvarı davranışına bağlı
olduğundan sabit bir saniye sınırı yerine önceki sürüme göre belirgin gerileme,
çökme ve arayüz kilitlenmesi izlenir.

## Kod yapısı

Tarama yaşam döngüsü ile ekran bileşenleri ayrılmıştır. Tarama kontrolleri,
durum/özet alanları ve cihaz kartları ayrı sunum dosyalarında tutulur. Geçmiş
ayrıntıları, referans karşılaştırması ve SQLite JSON dönüştürmeleri de bağımsız
modüllerdir; böylece arayüz, karşılaştırma kuralları ve veri saklama kodu
birbirine karışmadan geliştirilebilir.
