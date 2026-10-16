# OUI registry asset

`oui_registry.tsv`, `tool/update_oui_registry.dart` tarafından IEEE
Registration Authority genel MA-L, MA-M, MA-S ve IAB CSV listelerinden
üretilir:

https://standards.ieee.org/products-programs/regauth/

Uygulama bu dosyayı çevrimdışı kullanır ve çalışma sırasında IEEE'ye veya başka
bir üretici servisine istek göndermez. İlk yorum satırlarındaki tarih hangi
snapshot'ın kullanıldığını belirtir.

IEEE ve kayıt sahiplerine ait adlar yalnız gözlemlenen genel MAC prefix'inin
kayıtlı organizasyonunu göstermek için kullanılır. Proje farklı bir biçimde
dağıtılmadan veya yayımlanmadan önce geçerli IEEE kullanım ve yeniden dağıtım
koşulları yeniden kontrol edilmelidir.
