---
numbersections: true
---

# Bevezetés

A mai világban körbevesznek minket a számítógépek. A zsebünkben lévő okostelefontól kezdve, a nappalinkban lévő televízión és számítógépen át, egészen a bolti vásárlásainkat segítő kioszkokig. Egyes kutatások szerint, egy személynek átlagosan **3,6**[@cisco] okos eszköze van. Ezeknek az eszközöknek viszont a lehetőségeit korlátozza, hogy eredendően számítási és I/O kapacitása megoszlik. Ezekkel a problémákkal többen is foglalkoznak, mind számítási^[például Slurm, Spark és egyéb HPC szoftverek], mind bemeneti oldalról^[KVM-ek, a Synergy nevű program], de a kimeneti kérdésre kevesebb megoldás létezik, és azok vagy komplexek és nehezen kezelhetőek, vagy elavultak.

Szakdolgozatom egy interaktív webes alkalmazás, ami ezt az űrt hivatott betölteni. Segítségével több webböngészésre képes eszköz kijelzőjét fel tudjuk használni egy kijelzőként. Ezeket az egyesített kijelzőket (továbbiakban virtuális kijelzőket) használhatjuk különböző médiatartalmak megjelenítésére, például képek, videók, prezentációk.

Szakdolgozatomnak inspirációul a Junkyard Jumbotron[@jumbotron] projekt szolgált.

# Felhasználói dokumentáció {#sec:userdocs}

Az alkalmazás központilag kiszolgálva elérhető a https://getcrossview.com címen.

## Saját kezű kiszolgálás

Ha az alkalmazást saját szerverről szeretnénk kiszolgálni, akkor a Docker Compose[@docker-compose] alapú telepítés javasolt.

Az alapértelmezett konfiguráció egy szerverről szolgálja ki az összes szolgáltatást, melyeket egy proxy segítségével kapcsol össze. Ehhez szükséges, hogy a szolgáltatásoknak legyenek létrehozva a megfelelő aldomainek, amelyek mind a szerverre mutatnak.

A szükséges domainek (zárójelben a központilag kiszolgált domainek)

- A fő alkalmazás domainje (`getcrossview.com`/`www.getcrossview.com`)
- A Minio (S3 tárhely) domainje (`minio.getcrossview.com`)
- A Minio műszerfal domainje (`dashboard.getcrossview.com`)

Lokális futtatás esetén elég a HOSTS fájl szerkesztése. Erről több információt a -@sec:hosts fejezetben találhat.

1. Telepítse fel a Docker[@docker]-t. Ehhez elérhető segédletet a [docker.com](https://docs.docker.com/engine/install/)^[https://docs.docker.com/engine/install/] oldalon találhat.
2. Hozza létre a szükséges .env fájlokat

   - `main.env`

     1. Másolja le a `main.env.example` fájlt `main.env` néven
     2. Nyissa meg szerkesztésre
     3. Állítsa be az `S3_ENDPOINT` változót a Minio domainjére

     A többi változót a Minio konfigurálása után állítjuk be

   - `minio.env`
     1. Másolja le a `minio.env.example` fájlt `minio.env` néven
     2. Nyissa meg szerkesztésre
     3. Hozzon létre egy biztonságos jelszót, majd állítsa be rá a `MINIO_ROOT_PASSWORD` változót
     4. _[opcionális]_ Állítson be egy új felhasználónevet a `MINIO_ROOT_USER` változóval

3. Módosítsa az Nginx konfigurációt (`nginx.prod.conf`).
   Állítsa át a `server_name` kezdetű sorokat úgy, hogy a szolgáltatások az ön által megadott domaint szolgálják ki.
4. Indítsa el a szolgáltatásokat a `docker compose -f docker-compose.prod.yml up` paranccsal
5. Konfigurálja a Minio-t
   1. Menjen fel a Minio műszerfal oldalára, és lépjen be a `minio.env`-ben megadott adatokkal.
   2. Állítsa be a régiót a Configuration$\rightarrow$Region oldalon. Legyen `us-east-1`
   3. A buckets oldalon hozzon létre két vödröt:
      - `calibrations`
      - `media`
   4. Állítsa be a vödröknek, hogy publikusan olvashatóak legyenek
      - Kattintson rá a vödörre
      - A Summary aloldalon az Access Policy beállításnál válassza ki a `Custom` Access Policy-t
      - Használja a következő irányelvet (ezzel a vödör bárki által olvasható lesz):

        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": "*",
              "Action": "s3:GetObject",
              "Resource": "arn:aws:s3:::*"
            }
          ]
        }
        ```

   5. Hozzon létre egy hozzáférési kulcsot az Access Keys oldalon. Mentse el biztonságos helyre az Access Key-t és a Secret Key-t is.
6. Szerkessze a `main.env` fájl a most létrehozott hozzáférési kulccsal
   - az `S3_ACCESS_KEY_ID` legyen az Access Key
   - az `S3_SECRET_ACCESS_KEY_ID` legyen a Secret Key
7. Indítsa újra a szolgáltatásokat

## Használat

Az alkalmazást megnyitva a főoldalt láthatjuk (-@fig:main. ábra). Ezen az oldalon tudunk új **szobát** létrehozni, vagy egy már létező szobához csatlakozni. Minden szobához tartozik egy 8 karakter hosszú kód, ami azt a szobát egyedileg azonosítja. Ez a kód a szobák bal felső sarkában látható.

![A főoldal](images/main.png){#fig:main}

A szobák nézete két fő dologtól függ: a szoba **állapotától**, és a kliens **szerepétől**.

A szobákban lévő klienseknek két lehetséges **szerepe** van:

- Konfiguráló

  Ezek a kliensek felelnek a médiatartalmak kiválasztásáért, illetve a kijelzők helyzetének kalibrálásáért.

- Megjelenítő

  Ezeknek a klienseknek feladata, hogy a jelenleg megjelenítendő médiatartalomnak megjelenítsék azt a részét, amit az adott klienshez rendeltünk a kalibrálás során.

Egy **konfiguráló kliensből megjelenítő klienst lehet csinálni** a jobb felső sarokban lévő `View` gomb kattintásával.

A szobáknak két lehetséges **állapota** van:

- Kalibrálás

  Ebben az állapotban minden megjelenítő kliensen egy kalibráló jel jelenik meg. A konfiguráló kliensek feltölthetnek egy, a megjelenítő kliensekről készített fényképet (kalibrációs képet).

- Közvetítés

  Ebben az állapotban tudnak a konfiguráló kliensek médiatartalmakat kiválasztani, amiket a megjelenítő kliensek megjelenítenek. Ebbe az állapotba csak akkor lehet eljutni, ha a kalibrációs kép feldolgozása sikeres volt.

A két állapot között a konfiguráló kliensek tudnak váltani, az alkalmazás tetején levő gombpárral.

### Kalibrálási állapot használata

Ahhoz, hogy minden kijelző síkbeli elhelyezkedését tudjuk, szükséges egy kalibrációs lépés.

A kalibrálás során a felhasználó előkészítheti a megjelenítő klienseket. A legjobb eredmény elérésének érdekében próbáljuk meg az összes kijelzőt egy síkba helyezni.

A megjelenítő klienseken egy kalibráló kód jelenik meg a jobb oldalon, illetve a bal oldalon a szoba kódja és a kliens egyedi sorszáma (-@fig:apriltag. ábra).

![Megjelenítő kliens a kalibrálási állapotban.](images/apriltag.png){#fig:apriltag width=50%}

A konfigurációs kliens ebben az állapotban egy `Upload calibration image` (`Kalibrációs kép feltöltése`) gombot lát és a legutóbb feltöltött kalibrációs képet (-@fig:calibrationbefore. ábra).

![Konfiguráló kliens a kalibrálási állapotban.](images/calibration-before.png){#fig:calibrationbefore width=50%}

A felhasználónak egy fényképet kell készítenie a megjelenítő kliensekről. Ez lesz a **kalibrációs kép**. A kalibrációs kép kiterjesztése a következők egyike legyen: `.png, .jfif, .jpeg, .jpg, .webp, .avif, .heic, .heif`. Fontos, hogy a kalibrációs képen mindegyik klienshez tartozó kalibráló jel teljesen látszódjon, ugyanakkor a kijelzők többi része elhagyható a fényképről. A legjobb eredmény elérésének érdekében a fényképet nagyjából abból a szemszögből készítsük, ahonnan a virtuális kijelzőt nézni szeretnénk.

A fénykép feltöltése és a sikeres kalibrálás után megjelenik a kalibrációs kép, méretre vágva. A fénykép szürkeárnyalatosan jelenik meg, viszont a felismert kijelzők a hozzájuk tartozó színnel lesznek kiemelve (-@fig:calibrationafter. ábra).

![Konfiguráló kliens a kalibrálási állapotban, sikeres kalibrálás után.](images/calibration-after.png){#fig:calibrationafter width=50%}

Sikeres kalibrálás után elérhetővé válik a `Broadcast` gomb, amivel áttérhetünk a közvetítési állapotba.

### Közvetítési állapot használata

A médiatartalmak elindítását és előnézetét a közvetítési állapotban lehet megtenni.

A közvetítési állapotban a megjelenítő kliensek csak a virtuális kijelző tartalmát jelenítik meg.

A konfiguráló kliensnek lehetősége van médiatartalmak típusát kiválasztani, a médiatartalmat kiválasztani, és a típustól függően feltölteni.

Bal oldalon található a típus kiválasztó **(1)**, tőle jobbra az adott típus konfigurációs panelje **(2)**, majd a jobb oldalon egy előnézet **(3)**. Az előnézet alatt opcionálisan megjelenhetnek az adott típushoz tartozó vezérlők is **(4)**.

![A konfiguráló kliens nézete a közvetítési állapotban](images/broadcast.png){width=50%}

Jelenleg három médiatartalom típus elérhető:

- Fénykép
- Videó
- iFrame

#### Fényképek közvetítése

A bal sávon válasszuk ki a "Photos" lehetőséget. Ezzel láthatóvá válik a fénykép kezelő panel. Itt tudunk feltölteni képeket, illetve már feltöltött képeket "kiküldeni" a virtuális kijelzőre.

Ennek a típusnak nincsenek vezérlői.

#### Videók közvetítése

A bal sávon válasszuk ki a "Videos" lehetőséget. Ezzel láthatóvá válik a videó kezelő panel. Itt meg tudunk adni egy videó elérési címét, amit megjeleníthetünk a virtuális kijelzőn.

A cím jelenleg csak YouTube videóra mutató URL lehet.

A videó médiatartalom típus elérhetővé tesz egy vezérlő gombot is: a szünet/lejátszás (pause/play) gombot.

#### iFrame közvetítés (haladó)

Az alkalmazásban elérhető egy **haladóknak szánt** iFrame opció is. Ezzel egy tetszőleges weboldalt lehet megjeleníteni a virtuális kijelzőn. Fontos, hogy ez az opció nem hajt végre szinkronizálást a kliensek között, illetve csak olyan weboldalakkal működik, amelyek engedik az iFrame beágyazást.

Egy egyszerű példa a VDO.ninja[@video-ninja] szolgáltatás használata, egy kijelző képének megosztására.

1. Menjünk fel a https://vdo.ninja oldalra.
2. Válasszuk ki a "Remote Screenshare into OBS" lehetőséget
3. Válasszuk ki a megosztani kívánt kijelzőt
4. Másoljuk ki az oldal tetején található `https://vdo.ninja/?view/??????` linket a mellette lévő \twemoji{paperclip} gomb segítségével.
5. Menjünk át a CrossView szobánkba, ami már be van állítva Közvetítési állapotra
6. Válasszuk ki az iFrame médiatartalom típust
7. Másoljuk be az előbbi linket
8. Adjuk hozzá a következő tagot: `&na` (ez kikapcsolja a hangot, ezzel engedélyezve az automatikus lejátszást)

A [vdo.ninja](https://vdo.ninja) szolgáltatást több más dologra is lehet használni, például webkamerák megosztására, [Android illetve iOS eszközökről való közvetítésre](https://docs.vdo.ninja/steves-helper-apps/native-mobile-app-versions)^[https://docs.vdo.ninja/steves-helper-apps/native-mobile-app-versions] (natív alkalmazások segítségével), vagy akár az [OBS nevű szoftverből közvetíteni](https://docs.vdo.ninja/guides/from-obs-to-vdo.ninja-using-whip)^[https://docs.vdo.ninja/guides/from-obs-to-vdo.ninja-using-whip].

A vdo.ninja további lehetőségeiről a [dokumentációjában](https://docs.vdo.ninja/)^[https://docs.vdo.ninja/] lehet olvasni.

# Fejlesztői dokumentáció

A projekt magja a "Main Service" nevű React alapú full-stack alkalmazás. Ez implementálja mind a backend, mind a frontend funkcionalitást.

A kalibráláshoz készült egy "Apriltag Service" nevű Pythonos komponens is, ami egy microservice-ként funkcionál, és a kalibráló jelek felismerését, illetve egyes kalibráláshoz kapcsolódó matematikai számításokat hajt végre.

Külső fejlesztésű szolgáltatásként van használva a Redis mint adatbázis, és a Minio mint S3 kompatibilis tárhely.

## Quick Start

A fejlesztői környezet telepítése hasonló a prod környezetéhez. A főbb különbség, hogy a `docker-compose.prod.yml` és az `nginx.prod.conf` helyett a `docker-compose.dev.yml` és az `nginx.dev.conf` fájlokat kell módosítani.

1. Telepítse fel a Docker-t. Ehhez elérhető segédletet a [docker.com](https://docs.docker.com/engine/install/)^[https://docs.docker.com/engine/install/] oldalon találhat.
2. Hozza létre a szükséges .env fájlokat

   - `main.env`

     1. Másolja le a `main.env.example` fájlt `main.env` néven
     2. Nyissa meg szerkesztésre
     3. Állítsa be az `S3_ENDPOINT` változót a Minio domainjére

     A többi változót a Minio konfigurálása után állítjuk be

   - `minio.env`
     1. Másolja le a `minio.env.example` fájlt `minio.env` néven
     2. Nyissa meg szerkesztésre
     3. Hozzon létre egy biztonságos jelszót, majd állítsa be rá a `MINIO_ROOT_PASSWORD` változót
     4. _[opcionális]_ Állítson be egy új felhasználónevet a `MINIO_ROOT_USER` változóval

3. Módosítsa az Nginx konfigurációt (`nginx.dev.conf`).
   Állítsa át a `server_name` kezdetű sorokat úgy, hogy a szolgáltatások az ön által megadott domaint szolgálják ki.
4. Indítsa el a szolgáltatásokat a `docker compose -f docker-compose.dev.yml up` paranccsal
5. Konfigurálja a Minio-t
   1. Menjen fel a Minio műszerfal oldalára, és lépjen be a `minio.env`-ben megadott adatokkal.
   2. Állítsa be a régiót a Configuration$\rightarrow$Region oldalon. Legyen `us-east-1`
   3. A buckets oldalon hozzon létre két vödröt:
      - `calibrations`
      - `media`
   4. Állítsa be a vödröknek, hogy publikusan olvashatóak legyenek
      - Kattintson rá a vödörre
      - A Summary aloldalon az Access Policy beállításnál válassza ki a `Custom` Access Policy-t
      - Használja a következő irányelvet (ezzel a vödör bárki által olvasható lesz):

        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": "*",
              "Action": "s3:GetObject",
              "Resource": "arn:aws:s3:::*"
            }
          ]
        }
        ```

   5. Hozzon létre egy hozzáférési kulcsot az Access Keys oldalon. Mentse el biztonságos helyre az Access Key-t és a Secret Key-t is.
6. Szerkessze a `main.env` fájl a most létrehozott hozzáférési kulccsal
   - az `S3_ACCESS_KEY_ID` legyen az Access Key
   - az `S3_SECRET_ACCESS_KEY_ID` legyen a Secret Key
7. Indítsa újra a szolgáltatásokat

### Lokális domain használata {#sec:hosts}

Lokális tesztelés esetén hasznos lehet, ha nem kell egy külső domaint használni. Ennek a legegyszerűbb módszere egy HOSTS fájl létrehozása.

#### HOSTS fájl Windows operációs rendszeren

1. Indítsa el a Jegyzettömböt rendszergazda jogosultságokkal
2. Nyissa meg a `C:\Windows\System32\drivers\etc\hosts` fájlt (szükséges lehet kiválasztani a "Minden fájl (\*.\*)" opciót)
3. Adja hozzá a következő sorokat:

    ```
    127.0.0.1 getcrossview.com
    127.0.0.1 www.getcrossview.com
    127.0.0.1 apriltag.getcrossview.com
    127.0.0.1 minio.getcrossview.com
    127.0.0.1 dashboard.getcrossview.com
    ```

4. Mentse el a fájlt

#### HOSTS fájl Linux/MacOS operációs rendszeren

1. Nyisson meg egy Terminált
2. A következő paranccsal indítsa el a `nano`-t rendszergazda jogosultságokkal:

    ```
    sudo nano /etc/hosts
    ```

3. Adja hozzá a következő sorokat:

    ```
    127.0.0.1 getcrossview.com www.getcrossview.com
    127.0.0.1 apriltag.getcrossview.com
    127.0.0.1 minio.getcrossview.com
    127.0.0.1 dashboard.getcrossview.com
    ```

4. Mentse el a fájlt

## Overview

Ennek a fejezetnek az elolvasása előtt érdemes elolvasni a -@sec:userdocs. (felhasználói dokumentáció) fejezetet.

Az alkalmazás szobákra van osztva, amelyek egymástól függetlenül működnek. Minden szoba 24 óráig elérhető.

A szobáknak van egy azonosítója, amely egy szekvenciális sorszámból van generálva egy determinisztikus algoritmussal (lásd: -@sec:roomcode. fejezet ). Ez biztosítja, hogy egyszerre két szoba nem kaphatja meg ugyan azt a kódot.

Minden szobához tartozhat egy kalibrációs kép, amely a legutóbb feltöltött kalibráció szerint készül. Kalibrálási állapotba csak akkor lehet áttérni, ha van ilyen kép. Ezen felül minden szobához tartozhatnak feltöltött fényképek, amelyeket a közvetítési állapotban lehet használni.

Minden megjelenítő kliensnek van egy egyedi azonosító sorszáma. Ez a sorszám az elérési útban tárolódik el. A megjelenített kalibráló jel (Apriltag[@wang2016iros]) sorszáma megegyezik a kliens sorszámával.

A kalibráció során a képen az Apriltag Service megkeresi az összes kalibráló jelet, majd az azokból megtalált homográfiákból[@opencv-homography] és a jelek elhelyezkedéséből létrehoz egy egész kijelzős homográfiát, és egy virtuális koordináta-rendszerbe helyezi őket.

Közvetítési állapotba érve a megjelenítő kliensek a hozzájuk tartozó homográfiát használva egy `div`-re CSS `transform`-ot helyez (`ScreenContent`). Ez a `transform` vetíti ki a `div` tartalmát a megjelenítő kliens kijelzőjére úgy, hogy a kijelzők egy koherens képet alkossanak.

A homográfiák létrehozásáról további információ a -@sec:matrices. fejezetben található.

A `ScreenContent` komponens a szoba jelenlegi adatai szerint töltődik fel a megfelelő tartalommal. Mivel a vetítést a CSS `transform` végzi, ezért ennek a komponensnek nem kell foglalkoznia vele, csak a szinkronizálást kell implementálnia, ahol lehet (pl. videó jelenlegi timestampjének szinkronizálása a kliensek között).

## Adatbázis

A projekthez a Redis adatbázis szoftvert használtam. A Redis egy kulcs-érték adatbázis, ahol minden elérhető rögtön a memóriából, ezért gyakran használják például gyorsítótárakhoz.

A Redis több szempontból is előnyös ehhez a projekthez:

- gyors, hiszen minden memóriában van tárolva
- mivel nincs huzamosabb ideig tárolt adat, ezért a memóriaigény alacsony
- az adatok strukturálatlanok, így nincs előnye az adatok táblákba rendezésének
- beépített támogatás az alkalmazáson belüli üzenetküldésre (ezzel megkönnyítve a valós idejű adatszolgáltatást)

Természetesen ez a választás hátrányokkal is járt:

- a kulcs-érték felépítés miatt nincs széles körű ORM támogatás, az adatbázishoz tartozó boilerplate kódod sajátkezűleg kell megírni
- a JSON szerű adatbázisokhoz képest (pl. MongoDB) a Redis egy flat struktúrában tárolja az adatokat. Ennek hátránya, hogy hierarchikus adatok tárolására csak jól meggondolt kulcsokkal van lehetőség (Például: `room:ROOM:photos:PHOTO:path`).

  Természetesen azért, hogy az SQL injection-re hajazó problémákat elkerüljük, szükséges, hogy a kulcs dinamikusan megadható tagjai validálva legyenek. Egy `:`-ot tartalmazó ROOM könnyen problémákat okozhat a kódban.

### Adatbázis séma

Az alábbiakban a szoftver különböző komponenseiben használt Redis kulcsok találhatóak.

A kulcsban `NAGY BETŰVEL` vannak jelölve a dinamikusan beillesztendő tagok:

- `ROOM`: a szoba kódja
- `SCREEN`: a megjelenítő kliens sorszáma
- `PHOTO`: a szobába feltöltött egyik fénykép UUID-je

#### Szoba-szintű adatbázis elemek

| Kulcs | Típus | Leírás |
| ---- | --- | --------- |
| roomCount | Szám | A létrehozott szobák számát tárolja. Értelmezhető úgy is, mint a legutoljára létrehozott szoba sorszáma. |
| `room:ROOM` | PubSub csatorna | Ezzel a kulccsal nem létezik kulcs-érték páros. Ez a kulcs a [Pub/Sub](https://redis.io/docs/latest/develop/interact/pubsub/)^[https://redis.io/docs/latest/develop/interact/pubsub/] üzeneteknek van fenntartva. Jelenleg csak a `ping` string küldhető el rajta. További információ: -@sec:pubsub. fejezet |
| `room:ROOM:mode` | string | A szoba jelenlegi állapota. Értéke csak `calibration` (kalibrálás) vagy `viewing` (közvetítés) lehet. |
| `room:ROOM:image` | string | A szoba jelenlegi kalibrációs képének S3-beli neve, kiterjesztéssel együtt. |
| `room:ROOM:width` | Szám | A szoba jelenlegi kalibrációs képének szélessége pixelben. |
| `room:ROOM:height` | Szám | A szoba jelenlegi kalibrációs képének magassága pixelben. |

##### Szoba kód generálása {#sec:roomcode}

Új szoba létrehozásakor a roomCount-ból szükséges létrehozni egy szoba kódot. Ehhez a [!LCG] random szám algoritmus indexelhetőségét^[[@rotenberg1960pseudo], 2. egyenlete] használom ki. Ezt a következő kódrészlet implementálja a `mainservice/src/lib/utils.ts` fájlban^[Az `a` és `c` változók a Microsoft `rand` függvénye szerint lettek kiválasztva [@lomont2008random]]:


```typescript
export function keyToCode(key: number, length = CODE_LENGTH) {
  const a = BigInt(214013);
  const c = BigInt(2531011);

  const bigkey = BigInt(key);

  // Megkeresem a key-edik értéket a random szám sorozatban
  // https://math.stackexchange.com/a/2115780
  // Megegyezik Rotenberg1960 2. egyenletével, ha az ott lévő (2^a + 1)-et a-ra cseréljük
  const modulo = BigInt(CODE_ALPHABET.length) ** BigInt(length);
  const apowkey = powmod(a, bigkey, modulo);
  let num = (apowkey + ((apowkey - 1n) / (a - 1n)) * c) % modulo;

  // Átalakítom stringgé
  let code = "";
  for (let i = 0; i < length; i++) {
    code += CODE_ALPHABET[Number(num) % CODE_ALPHABET.length];
    num = num / BigInt(CODE_ALPHABET.length);
  }
  return code;
}
```

#### Kijelző-szintű adatbázis elemek

| Kulcs | Típus | Leírás |
| ----- | -- | --- |
| `room:ROOM:screenCount` | Szám | Egy szobához tartozó megjelenítő kliensek száma |
| `room:ROOM:available` | Szám halmaz | Egy szobához tartozó jelenleg elérhető megjelenítő kliensek sorszámának halmaza |
| `room:ROOM:screen:SCREEN:config` | JSON string - { width: number, height: number, x: number, y: number } | A megjelenítő kliensek kalibráló jelének helye és mérete a kijelzőn. Jelenleg ez pontosan a képernyő jobb fele |
| `room:ROOM:screen:SCREEN:ping` | Szám | Mindig `1`. Az [EXPIRE](https://redis.io/docs/latest/commands/expire/)^[https://redis.io/docs/latest/commands/expire/] értéke 2 percre van beállítva, és a kliensek 30 másodpercenként újra létrehozzák. Ezzel lehet észlelni kliens timeout-ot. Lásd: -@sec:timeout. fejezet |
| `room:ROOM:screen:SCREEN:homography` | JSON string - 3x3-as szám mátrix | Az Apriltag Service által generált homográfia. Lásd: -@sec:matrices. fejezet |

##### Megjelenítő kliens timeout {#sec:timeout}

Egyes esetekben nem lehet egyértelműen eldönteni, hogy a megjelenítő kliens mikor csatlakozott le. Ennek az észlelésére van beépítve egy pingelő rendszer az alkalmazásba. A kliens 30 másodpercenként hívja meg a `sendPing` szerveroldali függvényt, amely a `room:ROOM:screen:SCREEN:ping` kulcsú értéket `1`-re állítja, 2 perces EXPIRE értékkel. Így a kulcs nem fog eltűnni, amíg létezik a megjelenítő kliens. 

A kulcs eltűnését egy [keyspace notification](https://redis.io/docs/latest/develop/use/keyspace-notifications/)^[https://redis.io/docs/latest/develop/use/keyspace-notifications/] segítségével vesszük észre. 

```ts
// A ping kulcsot match-elő regex
const screenKeyRegex = /^room:([^:]+):screen:(\d+):ping$/;

export async function setupScreenExpiry(redis: RedisClientType) {
  // keyspace notification-ök bekapcsolása "Keyevent, expire" módban
  await redis.configSet("notify-keyspace-events", "Ex");
  // Új Redis kliens létrehozása, mivel subscribe mellett más művelet nem hajtható végre
  const listener = redis.duplicate();
  await listener.connect();

  // Ez az event meghívódik bármilyen kulcs lejártakor
  void listener.subscribe("__keyevent@0__:expired", (key) => {
    // Ha a kulcs az egy kijelző timeout-hoz tartozik, akkor hívja le a deregisterScreen függvényt az adott kijelzőn
    const matches = key.match(screenKeyRegex);
    if (matches === null) {
      return;
    }
    const roomID = matches[1];
    const screenID = matches[2];
    void deregisterScreen(roomID, Number(screenID));
  });
}
```

Jelenleg a `deregisterScreen` függvény használaton kívül áll.

#### Jelenlegi közvetítéshez tartozó adatbázis elemek

| Kulcs | Típus | Leírás |
| ----- | -- | --- |
| `room:ROOM:content:type` | String ( `none` \| `photo` \| `video` \| `iframe` ) | A jelenlegi tartalom típusa. `none` ha nincs kiválasztva tartalom típus |
| `room:ROOM:content:url` | String | Fénykép médiatípus esetén a tartalom neve a media vödörben. Videó és iFrame esetén a tartalom teljes URL-je. |
| `room:ROOM:content:status:type` | String (`paused` \| `playing`) | Videó tartalom esetén a lejátszás jelenlegi állapota |
| `room:ROOM:content:status:timestamp` | Szám | Videó tartalom esetén a lejátszás állapotának megváltoztatási ideje, UNIX idő milliszekundumban |
| `room:ROOM:content:status:videotime` | Szám | Videó tartalom esetén használatos. A videó ideje másodpercben, a videó lejátszási állapot megváltozásának pillanatában |

#### Feltöltött fényképekhez tartozó adatbázis elemek

| Kulcs | Típus | Leírás |
| ---- | -- | ---- |
| `room:ROOM:photos` | String halmaz | A szobába feltöltött fényképek UUID azonosítóját tartalmazó halmaz |
| `room:ROOM:photos:PHOTO:name` | String | A UUID-hoz tartozó fénykép eredeti fájlneve |
| `room:ROOM:photos:PHOTO:path` | String | A UUID-hoz tartozó fénykép fájlneve a media vödörben |

## Fájl tárolás {#sec:s3}

A fájlok tárolására egy S3[@s3] kompatibilis tárhely szolgáltatást használok. Ennek oka, hogy ez a de-facto szabvány, és nagyban megkönnyíti a fájlok le- és feltöltését.

A tárhely szolgáltatás amit használok, alapértelmezetten a Minio[@minio], hiszen jól támogatott és széleskörűen használt ^[a TheirStack[@theirstack] szerint több mint 1000 cég használja]. Természetesen bármilyen más S3 kompatibilis szolgáltatást le lehetne cserélni.

Az alkalmazás két S3 bucket-et (vödröt) használ:

- calibration

  Ide kerülnek a kalibrációs képek, illetve a perspektíva korrigált változataik
- media

  Ide kerülnek a megjelenítésre feltöltött fényképek

A `main.env`-ben megadott S3 felhasználónak mindkét vödörhöz kell, hogy kapjon írási és olvasási jogot is.

A vödröknek olvashatónak (de nem feltétlenül listázhatónak) kell lenniük vendégfelhasználók által is. A telepítési útmutatóban található policy ezt állítja be.

Az S3 protokoll engedélyez úgynevezett pre-signed URL[@s3-presigned] létrehozását. Egy pre-signed URL-t egy privilegizált felhasználó tud létrehozni, előre kitöltött adatokkal. Ekkor az URL-t használó vendég a privilegizált felhasználó jogait veszi át.

Pre-signed URL-ek két helyen vannak használatban az alkalmazásban:

- A kalibrációs kép/fénykép feltöltésekor

  A szerver létrehoz egy pre-signed URL-t a saját S3 felhasználójával, melyben megköti a vödröt, a fájl nevét, illetve a `Content-Length` header-t Így a kliens S3 vendégfelhasználóként is képes lesz írni a fájlt. A szerver le tudja ellenőrizni a klienstől kapott méret segítségével, hogy a fájl mérete nem halad-e meg egy limitet, majd a `Content-Length` megkötés biztosítja, hogy a kliens a megfelelő méretű adatot töltötte fel.
- A kalibrálás utáni perspektíva korrigált kalibrációs kép feltöltése

  A perspektíva korrekciót az Apriltag Service végzi, de nincs hozzáférése privilegizált S3 felhasználóhoz. Ahhoz, hogy mégis fel tudja tölteni a képet, kalibrálás előtt a szerver létrehoz neki egy pre-signed URL-t erre a célra.

## Main service

A projekthez a React keretrendszert használtam, mivel sokoldalú és széles körű használata miatt jól támogatott. Manapság sokféle "ízben" lehet használni a React-et. Én a Next.js[@nextjs] alapú `create-t3-app`-et[@t3] használtam. Ennek a választásnak több oka is volt:

- A Next.js az egyik legelterjedtebb keretrendszer még a React-es framework-ök között is, így ennek van a legjobb támogatottsága is
- A Next.js egy full stack rendszer. Szerver komponensek és akciók segítségével egyben lehet megírni vele a frontend-et és a backend-et^[https://nextjs.org/docs#what-is-nextjs].
- A `create-t3-app` egy kezdőcsomag, amely több gyakori konfigurációt beállít, illetve sok hasznos csomagot tartalmaz:
  - szigorú TypeScript[@typescript] támogatással érkezik, hogy biztosítsa minden sor kód típus helyességét
  - a `tRPC`[@trpc] könyvtárral egyszerűen lehet a szerver és a kliens kód között valós idejű kommunikációt végrehajtani
  - ezeken felül támogatja a Prisma ORM-et, a NextAuth.js autentikációs könyvtárat és a Tailwind-et, de ezekre ebben a projektben nem volt szükség

Az oldal UI felépítéséhez a Mantine[@mantine] stíluskönyvtárat használtam, amely az oldal felépítését nagyban megkönnyítette, ezen kívül sok hasznos hook-ot tartalmaz.

### Elérési utak

Mivel a Next.js elérés alapú routing-ot használ, ezért az oldalak elérési struktúrája határozza meg a projekt mappaszerkezetében való elhelyezkedését is.

Minden oldalhoz tartozik egy mappa, amelyben két fontosabb fájl található:

- `page.tsx`

  Ez a fájl írja le, hogy az adott elérési útnak mi legyen a tartalma
- `layout.tsx`

  Ez a fájl írja le, hogy ha az adott mappa része a teljes elérési útnak, akkor mi legyen az oldal tartalma körülötti díszítés.

  Például: Legyen a `src/app/example/test/page.tsx` tartalma a `ting` feliratot kiíró komponens, míg a `src/app/example/test/layout.tsx` tartalma:

  ```jsx
  export default function TestLayout({children}){
    return <>tes{children}</>
  }
  ```

  Ebben az esetben a `/example/test` oldalra érkezve a `testing` felirat vár minket.

A `[`szögletes zárójelben`]` lévő útrészletek dinamikus tagok, amelyek helyére bármilyen érték kerülhet

A `@`kukaccal kezdődő útrészlet tagok párhuzamos utak, amelyeket a közvetlenül felette lévő elérési út layout-ja bárhova elhelyezhet navigáció nélkül. Például a megjelenítő kliensnek két párhuzamos útja van, egy a kalibrálási állapothoz és egy a közvetítési állapothoz. A megjelenítő klienseknek fenntartott útvonal ezek között tud váltani az útvonal megváltoztatása nélkül.

Az alkalmazás különböző komponenseinek elérési oldalai, célja és a layout fájl hatása:

- `/` - belépés, új szoba létrehozása
  - `/api/trpc/[trpc]` - a tRPC-nek elkülönített elérési út
  - `/room/[room]` - a layout fájl itt teszi elérhetővé a szoba kontextusát
    - `/room/[room]/view` - generál egy új megjelenítő kliens sorszámot, majd átirányít a hozzá megfelelő oldalra
      - `/room/[room]/view/[screen]` - a layout fájl itt teszi elérhetővé a megjelenítő kliens kontextusát
        - `@viewing` - a közvetítési állapot esetén használt megjelenés
        - `@calibration` - a kalibrálási állapot esetén használt megjelenés
    - `/room/[room]/config` - a layout fájl hozzáadja a toolbar-t, amely kiírja a szoba kódját, a `Calibrate` és `Broadcast` gombokat, illetve a `View` gombot. Ezen felül automatikusan átirányít a szükséges aloldalra a jelenlegi állapottól függően
      - `/room/[room]/config/viewing` - a közvetítési állapot oldala. A layout adja hozzá a jobb oldali előnézetet, illetve a bal oldali médiatartalom típus választó panelt. A tartalmat a kettő közé helyezi el.
        - `/room/[room]/config/viewing/photo` - a fénykép médiatartalom konfigurálására szolgáló út
        - `/room/[room]/config/viewing/video` - a videó médiatartalom konfigurálására szolgáló út
        - `/room/[room]/config/viewing/iframe` - az iFrame médiatartalom konfigurálására szolgáló út
      - `/room/[room]/config/calibration` - a kalibrálási állapot oldala.

### Adatbázis elérése {#sec:db}

Mivel a Redis nem relációs adatbázis, ezért a klasszikus értelemben vett ORM-ek itt nem használhatóak. Az adatok kinyerésének egyszerűsítéséért új adatbázis elem esetén két dolgot kell létrehozni: egy kulcs helper-t, és egy adatbázis objektumot.

A kulcs helper az egy függvény a `src/db/redis-keys.ts` fájlban. Itt minden adatbázis elemhez tartozik egy függvény, ami megadja az elemnek a kulcsát Redis-ben Ez egy low-level absztrakció a Redis-hez, nem kezel se típusokat, se hibákat. A hierarchikus felépítés segítésének érdekében a hierarchia belső csúcsaihoz rendelek egy `...Root` helper-t A csúcs alatt lévő elemek ezt a root helper-t használják a saját kulcsuk létrehozására.

Például:

```ts
// Egy szobának megadja a root-ját
export function roomRoot(room: string) {
  return `room:${room}`;
}

// Egy szobának megadja a módját. Az előbb létrehozott roomRoot-ot használja
export function roomMode(room: string) {
  return `${roomRoot(room)}:mode`; // room:ROOM:mode
}

// A szobának adja meg a kalibrációs képét
export function roomImageRoot(room: string) {
  return `${roomRoot(room)}:image`; // room:ROOM:image
}

// A kalibrációs kép szélessége. Felhasználja a roomImageRoot-ot, és közvetetten a roomRoot-ot
export function roomImageWidth(room: string) {
  return `${roomImageRoot(room)}:width`;  // room:ROOM:image:width
}
```

Ahhoz, hogy fenntartsuk az adatbázis egységes használatát, minden adatbázis elemhez létrehoztam egy adatbázis objektumot a `src/db/objects` mappában. Mindegyik fájl egy-egy nagyobb logikai egységet valósít meg. Minden fájlban vagy top-level találhatóak az adatbázist elérő függvények (pl. `get`, `set`, `rem`), vagy hierarchikusan egy alárendelt objektumban.

Az adatbázis objektumok típusozottak, de nem szükséges, hogy a típust ellenőrizzék, amíg ezt a szignatúra fenntartja (feltételezve az adatbázis objektumok exkluzív használatát).

A Redis adatbázis objektumot a `node-redis` könyvtár segítségével érem el. A `db/redis.ts` fájlból exportált `getRedis` aszinkron függvény teszi elérhetővé az adatbázis singleton-t.

Egy pár példa:

```ts
/* roomCount.ts */
const roomCountObject = {
  async incr() {
    const redis = await getRedis();
    return await redis.incr(roomCount()); // NOTE: a roomCount az a redis-keys.ts fájlból jön
  },
  async get() {
    const redis = await getRedis();
    return Number((await redis.get(roomCount()))!);
  },
};

export default roomCountObject;
/* roomContent.ts */
const roomContentObject = {
  type: {
    async set(room: string, type: RoomContentType) {
      const redis = await getRedis();
      await redis.set(roomContentType(room), type);
    },
    async get(room: string): Promise<RoomContentType | null> {
      const redis = await getRedis();
      return (await redis.get(roomContentType(room))) as RoomContentType | null;
    },
  },
// [...]
}
```

#### Adatbázis objektumok listája {#sec:db-object}

| Adatbázis objektum név | Adatbázis kulcs | Metódusok |
| ---- | ------ | -- |
| `roomCount` | `roomCount` | `get`, `incr` |
| `roomContent.type` | `room:ROOM:content:type` | `set`, `get` |
| `roomContent.url` | `room:ROOM:content:url` | `set`, `get` |
| `roomContent.status` | `room:ROOM:content:status:type` | `set`, `get` |
| `roomContent.timestamp` | `room:ROOM:content:status:timestamp` | `set`, `get` |
| `roomContent.videotime` | `room:ROOM:content:status:videotime` | `set`, `get` |
| `roomImage.name` | `room:ROOM:image` | `set`, `get`  |
| `roomImage.width` | `room:ROOM:image:width` | `set`, `get`  |
| `roomImage.height` | `room:ROOM:image:height` | `set`, `get`  |
| `roomMode` | `room:ROOM:mode` | `set`, `get`  |
| `roomPhotos.photosSet` | `room:ROOM:photos` | `get`, `member`, `add`, `remove` |
| `roomPhotos.photoName` | `room:ROOM:photos:PHOTO:name` | `set`, `get` |
| `roomPhotos.photoPath` | `room:ROOM:photos:PHOTO:path` | `set`, `get` |
| `roomPubSub` | `room:ROOM` | `ping` |
| `roomRoot` | `room:ROOM` | `exists`, `touch` |
| `roomScreenAvailable` | `room:ROOM:available` | `members`, `add`, `rem` |
| `roomScreenCount` | `room:ROOM:screenCount` | `set`, `get`, `incr` |
| `screenConfig` | `room:ROOM:screen:SCREEN:config` | `set`, `get` |
| `screenHomography` | `room:ROOM:screen:SCREEN:homography` | `set`, `get`, `del` |
| `screenPing` | `room:ROOM:screen:SCREEN:ping` | `ping` |



### PubSub {#sec:pubsub}

Mivel a kijelző és a konfiguráló kliensek szoros kapcsolatban vannak, ezért szükséges egy valós idejű üzenetküldési megoldás. A megoldásom a következőképpen működik: bármilyen adat megváltoztatásakor, a megváltoztatást végző függvény egy `ping` üzenetet küld a `room:ROOM` csatornára, ezzel jelezve az új adat beérkezését. Mindegyik kliens egy tRPC[@trpc] subscription segítségével kapja meg a legfrissebb adatokat. A `ping` üzenetre a klienshez tartozó tRPC kiszolgáló lekéri a friss adatokat a Redis adatbázisból, szerializálja őket, majd elküldi egy [!SSE] kapcsolaton keresztül.

Az adatok kinyerése és a szerializáció a `src/db/serialization.ts` fájlban történik. Itt a `serializeRoom` aszinkron függvény a teljes szoba jelenlegi adatait visszaadja, JSON kódolható módon.

A szerializált struktúra a következő:

```ts
{
  // A megjelenítő kliensek legnagyobb sorszáma
  screenCount: number,
  // A megjelenítő kliensek adatai. A dimenzió adatok a kalibráló jelre vonatkoznak a kijelzőn belül, ami pontosan a képernyő jobb felét jelenti.
  serializedScreens: {
    // A kalibráló jel szélessége
    width: number,
    // A kalibráló jel magassága
    height: number,
    // A kalibráló jel kijelzőn belüli horizontális eltolása pixelben
    x: number,
    // A kalibráló jel kijelzőn belüli vertikális eltolása pixelben
    y: number,
    // A megjelenítő klienshez tartozó homográfia. Csak akkor van jelen, ha a kalibráció végbement, illetve a megjelenítő kliens jele megjelent fel lett rajta ismerve
    homography?: number[][]
  }[],
  // A szoba jelenlegi állapota: kalibrálási, illetve közvetítési
  mode: "calibration" | "viewing",
  uploaded: {
    // A feltöltött fényképek tömbje
    photos: {
      // A fénykép egyedi azonosítója
      id: string
      // A fényképfájl eredeti neve
      filename: string,
      // A fénykép neve az S3 tárhelyen
      url: string,
    }[]
  },
  // A kalibrációs kép adatai, ha végbement a kalibrálás
  image?: {
    // A kép neve az S3 tárhelyen
    filename: string,
    // A kép teljes URL-je, az S3 taggal együtt
    url: string,
    // A kép szélessége
    width: number,
    // A kép magassága
    height: number
  },
  // A jelenleg kiválasztott médiatartalom típusa és adatai
  nowPlayingContent: NowPlayingContent
}
```

A `NowPlayingContent` négy fajta lehet jelenleg:

- Nincs kiválasztva médiatartalom típus:

  ```ts
  {
    type: "none"
  }
  ```

- Fénykép médiatartalom:

  ```ts
  {
    type: "photo"
    // A fénykép teljes URL-je, az S3 taggal együtt
    url: string
  }
  ```
- Videó médiatartalom:

  ```ts
  {
    type: "video"
    // A videó URL-je
    url: string
    // A videó státusza. 
    status: {
      // Megállított vagy elindított videó
      type: "paused" | "playing",
      // A lejátszás állapotának megváltoztatási ideje, UNIX idő milliszekundumban
      timestamp: number,
      // A videó ideje másodpercben, az **üzenet küldésének pillanatában** (ellenben az adatbázisban található room:ROOM:content:status:videotime kulccsal)
      videotime: number,
    }
  }
  ```
- iFrame médiatartalom:

  ```ts
  {
    type: "iframe"
    // Az iFrame tartalmának URL-je
    url: string
  }
  ```

A szerializált adatot a kliens a `RoomContextProvider` komponensben veszi át, majd a `roomContext` Context[@react-context] segítségével az egész alkalmazás számára elérhetővé teszi azt. A Context a `useContext` hook-kal használható, két eleme a `lastEvent` tag, mely a legutóbb kapott szerializált üzenetet tartalmazza, illetve a `roomID`, amely a szoba kódját tartalmazza.

### Fájlok feltöltése

A -@sec:s3. fejezet ismerteti az S3 fájltárolás alapjait. Ez a fejezet fejlesztési szempontból közelíti meg a fájlok feltöltését.

Fájlok feltöltésére ajánlott használni a `RoomUploadButton` komponenst. Ez a komponens kezeli a töltési állapotot, kér egy pre-signed URL-t a szervertől, feltölti a fájlt az S3 szerverre, majd egy callback-et hív.

A komponens konfigurálásához négy paraméter szükséges:

- `title`

  A feltöltés gombra kiírandó szöveg
- `supportedMimeTypes`

  Azoknak a MIME[@rfc2046] típusoknak a tömbje, amelyeket engedünk feltölteni (ez csak frontend-en van ellenőrizve)
- `handleRequest`

  Egy szerver akció, ami megkapja a feltöltendő fájl nevét, méretét és a szoba kódját. Fontos, hogy ezeket az értékeket a kliens generálja, így ellenőrizendők: a szoba kódja a `codeValidation` Zod validációval, a fájl mérete a pre-signed URL-be égetett `Content-Length` fejléccel. Visszatérési értéke generikus, de mindenképpen tartalmaznia kell a pre-signed URL-t.
- `onUpload`

  Frontend oldalon hívott callback a sikeres feltöltés esetén. Paraméterként megkapja a handleRequest eredményét.

### Médiatípusok

A programban jelenleg 3 médiatartalom típus érhető el:

- Fénykép
- iFrame
- Videó

#### Új médiatartalom típus hozzáadása

A projekt felépítéséből adódóan könnyen lehet új médiatípusokat létrehozni a már létező rendszerek kihasználásával. Ennek fontos szerepe van a program bővíthetőségében, hiszen itt van a legtöbb lehetőség új funkciók beépítésére (például egy prezentáció mód, szinkronizált internet böngésző stb.)

Egy médiatípus öt részből áll:

- Egy Adatbázis objektumból
- Egy szerializációból
- Egy konfigurációs panelből
- Egy megjelenésből
- Opcionálisan egy vezérlő sorból

##### Médiatípus adatbázis objektumok

Első lépésként létre kell hoznunk a megfelelő adatbázis elemeket és objektumokat a médiatartalmunkhoz. Ezt a `room:ROOM:content` kulcs alatt, illetve a roomContent adatbázis objektumon belül tudjuk megtenni.


Először adjuk hozzá a `redis-keys.ts` fájlhoz a szükséges kulcsokat, a `roomContentRoot` kulcs helper (-@sec:db. fejezet) segítségével. Példának okául, tegyük fel, hogy egy prezentáció médiatípust szeretnénk hozzáadni. Ekkor szükséges lesz eltárolni a prezentáció URL-jét, illetve a jelenlegi diaszámot. Mivel az URL-re már létezik egy kulcs, ezért a diaszámnak hozzunk létre egy kulcsot:

```ts
export function roomContentSlide(room: string) {
  return `${roomContentRoot(room)}:slide`;
}
```

Utána az `src/db/objects/roomContent.ts` fájl kell kiegészíteni a megfelelő adatbázis objektummal. Az adatbázis objektumok leírása a -@sec:db. fejezetben található.

Szükséges rá odafigyelni, hogy az adatbázis sémát úgy kell létrehozni, hogy az akkor is működjön, ha egy megjelenítő kliens egy-egy parancs kiadása után csatlakozik. Tehát "eseményszerű" parancsokat mindenképpen át kell alakítani egy "állapotváltoztatás" paranccsá. Például, egy "videó elindítása" parancs helyett a videó elindításának időpontját kell megadni. A videó médiatípus implementálásáról további információ a -@sec:videomedia. fejezetben található.

##### Szerializáció

Mivel az adatbázis rendezetlenül adja vissza az adatokat, szükséges, hogy azokat egy rendezett formára alakítsuk át a kliens számára. Erre szolgál a szerializáció, amely a `src/db/serialization.ts` fájlban történik. A médiatartalom szerializálás a `serializeNowPlayingContent` függvény feladata.

Először, hozzunk létre egy TypeScript típust a médiatartalmunknak. A neve legyen `Serialized<NÉV>Content`. Mindenképpen legyen benne egy `type` attribútum, melynek típusa a médiatípusunk neve. Például:

```ts
export type SerializedPresentationContent = {
  type: "presentation",
  slide: number
}
```

Ezt a típust adjuk hozzá a `SerializedNowPlayingContent` unió lánchoz.

Hozzuk létre a `serialize<NÉV>Content` aszinkron függvényt, melynek paramétere a szoba kódja, és visszatérési értéke a fent létrehozott `Serialized<NÉV>Content` típus. Ennek a függvénynek a tartalma fog a kliens számára elérhető lenni.

Például:

```ts
async function serializePresentationContent(
  room: string
): Promise<SerializedPresentationContent> {
  const url = await roomContentObject.url.get(room);
  const slide = await roomContentObject.slide.get(room);
  return {
    type: "presentation",
    url,
    slide,
  };
}
```

Végül, adjuk hozzá ezt a függvényt a `serializeNowPlayingContent` függvényhez. Ehhez a switch-et kell kiegészíteni egy új elágazással, ami a médiatartalmunkhoz definiált `type` esetén meghívja a szerializáló függvényünket.

##### Konfigurációs panel

A konfigurációs panel az az, amit a felhasználó akkor lát, amikor rákattint a bal oldali médiatípus választó gombra. Ez Next.js-ben egy külön útvonalként van definiálva. A `src/app/room/[id]/config/viewing` mappában lehet létrehozni neki új mappát, majd a `src/app/room/[id]/config/viewing/layout.tsx` fájl `routes` tömbjének kiegészítésével lehet hozzáadni a bal oldali választóhoz.

A panelen kell lennie egy gombnak, amely elindítja a médiatartalmat. Ekkor a `roomContentObject` adatbázis objektum (-@sec:db-object. fejezet) `type` paraméterét a médiatípusnak megfelelő értékre kell állítani. Indítás után ne felejtsük el meghívni a `roomPubSubObject.ping` függvényt!

##### Megjelenés

A "megjelenés" az az a tartalom, ami a virtuális kijelzőn meg fog jelenni. Belépési pontja a `src/app/room/[id]/_screenContent/ScreenContent.tsx` komponens fájl, ami a virtuális kijelző tartalma. Ehhez a fájlhoz lehet hozzáadni az új médiatípushoz tartozó megjelenést. Célszerű ide a `_screenContent` mappába létrehozni egy új komponenst a megjelenésnek, és azt felhasználni. Fontos, hogy ez a komponens kitöltse a szülő komponenst, hiszen így lesz teljes képernyős a tartalom.

Például, ha a megjelenés komponens `PresentationContent` és a médiatípus type-ja `presentation`, akkor a következő sorokat kell hozzáadni a ScreenContent-hez:

```jsx
{room.lastEvent.nowPlayingContent.type === "presentation" ? (
        <PresentationContent
          style={{
            width: "100%",
            height: "100%",
          }}
        />
      ) : null}
```

##### Vezérlő sor

Ha a médiatípus elvárja az irányíthatóságot, akkor a `src/app/room/[id]/config/viewing/_controls/Controls.tsx` fájlban definiálható a médiatípusnak egy vezérlő komponens. Ezt a vezérlő komponenst célszerű ide az `_controls` mappába létrehozni.

Az adatbázis írása után ne felejtsük el meghívni a `roomPubSubObject.ping` függvényt!

#### Videó médiatartalom típus {#sec:videomedia}

Ez a fejezet a jelenlegi legkomplexebb médiatartalom típus, a videó lejátszás leírására szolgál.

A médiatípus komplexitása a szinkronizálásban rejlik, melynek megoldására egy egyszerű mechanizmust használok. Minden lejátszási állapot változáskor (szüneteltetés/indítás) a jelenlegi állapoton kívül elmentem azt is, hogy a szerver idejében mikor történt a változás, illetve hogy hol tartott a videó.

Videó leállításakor az elindítás óta eltelt idő és az akkori videó idő alapján kiszámolom, hogy mi az új videó idő, és azt tárolom el. Videó indításakor, mivel előtte szünetelt volt a videó, nem szükséges ezt a számítást megtenni.

Szerializációkor, ha a videó szünetel, akkor az adatbázisban tárolt videó időt küldöm a kliens felé. Viszont, ha a videó lejátszás alatt van, akkor a jelenlegi idő és a lejátszás kezdete alapján kiszámolom a jelenlegi videó időt, és a kliens már azt kapja meg.

## Kalibrálás

### Kalibrálási szolgáltatás

A kijelzők helyének pontos megállapításához szükséges egy kalibrálási fázis. Ehhez Apriltag[@wang2016iros]-eket használunk, amiknek gyorsan és pontosan <!--citation-->meg lehet határozni a helyzetét. 

Mivel a legtöbb számítógépes látás könyvtár és eszköz Python-ban érhető el, ezért ezt a lépést egy külön szolgáltatásban hajtom végre, melyet Apriltag Service-nek hívok. A következő könyvtárakat használom: 

- Az Apriltag-ek feldolgozására a `pupil-apriltags` könyvtárat
- A fényképek megnyitására, mentésére, perspektíva korrigálására az OpenCV könyvtárat (`opencv-python-headless`).
- Az egyéb mátrixos számításokhoz a `numpy` könyvtárat
- A Main Service-el való kommunikálás segítéséhez a FastAPI keretrendszert

Számítógépes látásban a különböző síkok közötti perspektíva transzformációkat egy homográfia mátrixszal lehet jellemezni[@opencv-homography]. Az Apriltag könyvtár egy ilyen homográfiát ad vissza minden kalibráló jelhez, ami az Apriltag saját koordináta-rendszeréből képez a fénykép koordináta-rendszerébe. Ezt kombinálva egy saját homográfiával, ami a megjelenítő kliens koordináta-rendszeréből (lásd: `room:ROOM:screen:SCREEN:config` ) képez az Apriltag koordináta-rendszerébe, kapunk egy homográfiát ami a kliens kijelzőjét jellemzi a fénykép keretein belül. Ez után a kliensek közül kiválasztunk egy "sablon kijelzőt" (ez a legkisebb sorszámú kliens jelenleg), és arra ortogonálisan létrehozunk egy olyan koordináta-rendszert, amelybe belefér az összes kliens kijelzője. Így jön létre a virtuális kijelző.

### Kalibrálási folyamat {#sec:matrices}

Mivel a homográfiák[@opencv-homography] mátrixok, egyszerűen lehet őket manipulálni az általános mátrix műveletekkel. Ezek közül a leggyakoribb a szorzás, ami két mátrix által definiált transzformációk egymás utáni alkalmazását reprezentálja egy mátrixszal.

A homográfiák eltolásokat is tartalmazhatnak. Általánosságban a mátrix egy $3 \times 3$-as mátrix, amelyben a jobb alsó elem pedig 1. Az utolsó oszlop első két eleme tartalmazza az eltolást, míg a bal felső $2 \times 2$-es mátrix tartalmazza a transzformáció többi részét.

A kalibrálási folyamat Apriltag Service-beli része két lépésre bontható:

- a kijelzők megkeresése
- és a virtuális kijelző létrehozása

A fejezetben a következő jelöléseket fogom használni:

- $image\_width, image\_height$ - a kalibrációs kép szélessége és magassága
- $virtual\_width, virtual\_height$ - a kalibrációs kép szélessége és magassága
- ${screen\_width}_i, {screen\_height}_i$ - az $i$-edik kijelző szélessége és magassága pixelben
- $H_i$ - Az $i$-edik kijelzőn lévő Apriltag homográfiája
- $M_i$ - Az $i$-edik kijelzőhöz tartozó homográfia
- $C$ - A kalibráló jel mérete pixelben
- $C_x, C_y$ - A kalibráló jel x és y eltolása a kijelzőn pixelben

Az Apriltag könyvtár minden megtalált kalibráló jelhez visszaadja a hozzá tartozó homográfiát. Ez a homográfia a jel koordináta-rendszeréből, ami $[-1, 1], [-1, 1]$ között van, átképez a fénykép koordináta-rendszerére, ahol pixel koordinátákkal dolgozunk ($[0, image\_width], [0, image\_height]$). Ezzel két probléma van. Egyrészt, a $[0, 1], [0, 1]$ koordinátákkal lehet a legegyszerűbben dolgozni, úgyhogy mind a forrás és a cél koordináta-rendszert erre át kell fordítani. Másrészt, a programban nem a kalibráló jel homográfiájára van szükségünk, hanem a teljes kijelzőjére.

Az első probléma megoldására két másik homográfiát lehet felhasználni: az egyik egy $[0, 1]$-es mátrixot alakít át $[-1, 1]$-essé (egy nagyítással és egy eltolással), a másik pedig a fénykép méretű koordinátát alakítja át $[0, 1]$ méretűvé:

$$\begin{bmatrix}
  \frac{1}{image\_width} & 0 & 0\\
  0 & \frac{1}{image\_height} & 0\\
  0 & 0 & 1\\
\end{bmatrix}
H_i
\begin{bmatrix}
  2 & 0 & -1\\
  0 & 2 & -1\\
  0 & 0 & 1\\
\end{bmatrix}$$

A másik problémát egy olyan homográfiával lehet megoldani, ami egy kijelzőbeli koordinátát alakít át egy kalibráló jelen belüli koordinátává. Ezt akkor lehetséges, ha tudjuk, hogy hol van a kijelzőn a jel, és hogy mekkora a mérete. Ezeket az adatokat szerencsére meg tudjuk szerezni a klienstől. Mivel egyszerűbb elképzelni, hogy egy kijelzőn belül hogyan lehet elhelyezni egy jelet, ezért arra hoztam létre homográfiát, majd azt invertáltam.

$$M_i \coloneqq \begin{bmatrix}
  \frac{1}{image\_width} & 0 & 0\\
  0 & \frac{1}{image\_height} & 0\\
  0 & 0 & 1\\
\end{bmatrix}
H_i
\begin{bmatrix}
  2 & 0 & -1\\
  0 & 2 & -1\\
  0 & 0 & 1\\
\end{bmatrix}
\begin{bmatrix}
  \frac{C}{W} & 0 & \frac{C_x}{W}\\
  0 & \frac{C}{H} & \frac{C_y}{H}\\
  0 & 0 & 1\\
\end{bmatrix}^{-1}$$

Most, hogy a kijelzőkhöz tartozó homográfiák megvannak, létre kell hozni a virtuális kijelző koordináta-rendszerét. Ehhez kiválasztok egy "sablon" kijelzőt, amire az új rendszer ortogonális lesz. Ennek a kijelzőnek a homográfiája legyen $M_0$. $M_0$ egy kijelzőn belüli pontot helyez el a kalibrációs képen, tehát $M_0^{-1}$ egy kalibrációs képen lévő pontot helyez el a kijelzőn belül.

Az algoritmus a következő:

1. Minden kijelzőnek megkeresem a sarkait a kalibrációs képen
2. A sarkokat a sablon kijelzőn elhelyezem a $M_0^{-1}$ mátrix segítségével.
3. A szélsőséges pontok megkeresésével megkapom a legkisebb téglalapot, amelybe az összes Apriltag beletartozik. Ez lesz a virtuális kijelző. 

   A kapott X és Y szélsőséges értékeknek nevet adok: $R, L$ a jobb és bal X koordináta, $T, B$ pedig a tetejének és az aljának az Y koordinátája (ezek a sablon kijelző koordináta-rendszerében vannak)

4. Létrehozok egy homográfiát, ami a $[0, 1], [0, 1]$ intervallumot a téglalapra képzi, a sablon kijelző koordináta-rendszerében.

    $$\begin{bmatrix}
    R-L & 0 & L \\
    0 & B-T & T \\
    0 & 0 & 1 \\
    \end{bmatrix}^{-1}$$

5. Mivel a téglalap a sablon kijelző koordináta-rendszerében van, a most létrehozott homográfiára alkalmazom a sablon kijelző homográfiáját is. Így egy olyan homográfiát kapok, ami a virtuális kijelző egy pontjából egy kalibrációs képbeli pontot hoz létre. Ez a homográfia legyen $V$.

    $$V \coloneqq M_0\begin{bmatrix}
    R-L & 0 & L \\
    0 & B-T & T \\
    0 & 0 & 1 \\
    \end{bmatrix}^{-1}$$
6. A kijelző homográfiákat átfordítom, hogy a virtuális kijelzőn legyenek.

    $$M_i' \coloneqq V^{-1}M_i$$

Az így kapott $M_i'$ mátrixok lesznek a kész homográfiák, amelyek a kliensek kijelzőinek pontjait a virtuális kijelző pontjaihoz rendeli.

A sablon kijelző felbontásából és a virtuális kijelzőn felvett méretéből ki tudunk számolni a virtuális kijelzőnek is egy felbontást: $virtual\_width$ és $virtual\_height$

Megjelenítéskor a frontend-en még szükség van egy átalakításra, hiszen a CSS `matrix3d` transzformáció pixel egységekben dolgozik. A transzformáció a virtuális kijelzőt reprezentáló `div`-re lesz alkalmazva, ezért a bemeneten annak a koordináta-rendszeréből kell egység méretű koordináta-rendszerbe hozni az értékeket. Viszont a kimeneten a transzformáció már a kliens kijelző méreteivel dolgozik, úgyhogy ott az egység méretű értékeket kell felnagyítani a kijelző méretére. Ezt a következő mátrixszal lehet megtenni:

$$T_i \coloneqq
\begin{bmatrix}
  {screen\_width}_i & 0 & 0 \\
  0 & {screen\_height}_i & 0 \\
  0 & 0 & 1 \\
\end{bmatrix}
{M_i'}^{-1}
\begin{bmatrix}
  virtual\_width & 0 & 0 \\
  0 & virtual\_height & 0 \\
  0 & 0 & 1 \\
\end{bmatrix}^{-1}$$

Végül, mivel a `matrix3d` transzformáció egy $4 \times 4$-es mátrixot vár, a fenti $3 \times 3$-as mátrixokat a megfelelő formára kell hozni. Ezt, egy általános $M$ mátrixszal a következő módon lehet megtenni:

$$M_{4 \times 4} \coloneqq \begin{bmatrix}
  M_{1, 1} & M_{1, 2} & 0 & M_{1, 3} \\
  M_{2, 1} & M_{2, 2} & 0 & M_{2, 3} \\
  0 & 0 & M_{3, 3} & 0 \\
  M_{3, 1} & M_{3, 2} & 0 & M_{3, 3} \\
\end{bmatrix}$$

## Tesztek

### Apriltag service tesztelése

A teszteléshez a FastAPI saját teszt rendszerét használtam[@fastapi-testing], ami pytest-re[@pytest] alapszik. Az S3 fel- és letöltés tesztelésére a `requests_mock`[@requests-mock] könyvtárat használtam.

A `mock_minio` pytest fixture[@requests-mock-pytest] létrehozza a megfelelő requests mock-okat, hogy minden fájl elérhető legyen úgy, mintha fent lenne az S3 tárhelyen.

A teszteléshez használt képek a `apriltagservice/test` mappában találhatóak.

#### Felállítás

A tesztek futtatásához szükséges egy Python környezet, amelynek verziószáma legalább 3.12. Ajánlott verzió: `3.12.9`. Ajánlott Linux-ot használni, vagy vagy Windows rendszereken WSL-t[@wsl].

1. Lépjen be az `apriltagservice` mappába
2. Hozzon létre új venv-et[@venv]: `python3.12 venv venv`
3. Lépjen be a virtualenv-be: `source venc/bin/activate`
4. Telepítse fel a projekt követelményeit: `pip install -r requirements.txt`
5. Telepítse fel a tesztelés követelményeit: `pip install pytest httpx requests-mock`
6. Futtassa a teszteket: `pytest`

#### Apriltag tesztek listája

| Teszt neve | Leírása | Kimenet |
| ----- | ---- | --- |
| `test_no_tag_no_screen` | Egy tesztkártya[@testcard] annak az esetnek a tesztelésére, ha nincs a képen Apriltag, és a Mainservice sem adott át kijelző méret adatokat. | `No tags have been found` hiba |
| `test_no_tag` | Egy tesztkártya[@testcard] annak az esetnek a tesztelésére, ha nincs a képen Apriltag. Egy kijelző dimenzió meg vannak adva. | `No tags have been found` hiba, mivel a kijelzők mérete nem ismert. |
| `test_one_tag_no_screen` | Egy Apriltag-ről készült kép, de kijelző dimenziók nélkül. | `No tags have been found` hiba, mivel a kijelzők mérete nem ismert. |
| `test_one_tag` | Egy teljes képernyős kép a megjelenítő kliens kalibrációs oldaláról. A dimenziók helyesen meg vannak adva. | Sikeres visszatérés, eredetivel megegyező felbontás, egy kijelző felismerve, amely az egész virtuális kijelzőt kitölti. |
| `test_one_tag_perspective` | Egy teljes képernyős kép a megjelenítő kliens kalibrációs oldaláról. A dimenziók helyesen meg vannak adva. A kép oldalasan készült. | Sikeres visszatérés, eredetivel megegyező felbontás, egy kijelző felismerve, amely az egész virtuális kijelzőt kitölti. |
| `test_one_tag_result` | Egy teljes képernyős kép a megjelenítő kliens kalibrációs oldaláról. A dimenziók helyesen meg vannak adva. A kép oldalasan készült. Meg van adva `upload_url`. | Sikeres visszatérés, `upload_url` meghívva, feltöltött bájtok megegyeznek a sablonnal (image_one_perspective\hspace{0pt}_warped.png) |
| `test_two_tag` | Egy kép melyen két megjelenítő kliens található egymás mellett. A tetején egy fejléc található. A dimenziók helyesen meg vannak adva. | Sikeres visszatérés, két kijelző felismerve, homográfiák szerint a kijelzők a virtuális kijelző két felét veszik fel |
| `test_two_tag_perspective` | Egy kép melyen két megjelenítő kliens található egymás mellett. A tetején egy fejléc található. A dimenziók helyesen meg vannak adva. A kép oldalasan készült. | Sikeres visszatérés, két kijelző felismerve, homográfiák szerint a kijelzők a virtuális kijelző két felét veszik fel |

## Mainservice tesztelése

![A Mainservice használati eset diagramja](images/usecases.svg)

| Leírás | Előkövetelmények | Teszt lépései | Várt eredmény |
| --- | ----- | ---- | ---- |
| Szoba létrehozás | Kezdőoldal megnyitva | Nyomja meg a "New room" gombot | Kis várakozás után létrejön egy szoba, és megnyílik kalibrálási állapotban |
| Szoba belépés | Létre van hozva egy szoba, kezdőoldal megnyitva | A "ROOM CODE" mezőbe írja be a szoba kódját, majd nyomjon a "Join" gombra  | Kis várakozás után belép a szobába, ahol a jelenlegi szoba jelenlegi állapota jelenik meg |
| Hibás formátumú szoba kód | Kezdőoldal megnyitva | Töltse ki a "ROOM CODE" mezőt egy 8 karakternél rövidebb szöveggel, például: `AAA`. Kattintson a "Join" gombra. | A böngésző a kezdőoldalon marad, és "String must contain exactly 8 character(s)" hibaüzenetet jelez. | 
| Nem létező szoba kód | Kezdőoldal megnyitva | Töltse ki a "ROOM CODE" mezőt egy 8 karakter hosszú szöveggel, például: `AAAAAAAA`, `12345678`, `@@@@@@@@`. Kattintson a "Join" gombra. | A böngésző a kezdőoldalon marad, és "Invalid code" hibaüzenetet jelez |
| Közvetítés, kalibrációs kép nélkül | Szoba megnyitva, **kalibrálási** állapotban, nincs feltöltve kalibrációs kép | Kattintson a "Broadcast" gombra | Nem történik semmi |
| Megjelenítő módba lépés | Szoba megnyitva, kalibrálási állapotban | Kattintson a "View" gombra | A kliens megjelenítő módba lép, jobb oldalt megjelenik egy kalibráló jel, bal oldalon a szoba kódja nem változott, a szoba kód melletti megjelenítő sorszám egyedi |
| Hibás kiterjesztésű kalibrációs kép | Szoba megnyitva, kalibrálási állapotban | Kattintson az "Upload calibration image" gombra, majd töltse fel a projekt mappából a `README.md` fájlt. | A bal alsó sarokban megjelenik egy "Invalid extension" hiba, a kalibrációs kép nem változik meg |
| Kalibrációs kép, kalibráló jel nélkül | Szoba megnyitva, kalibrálási állapotban | Kattintson az "Upload calibration image" gombra, majd töltse fel a projekt mappából az apriltagservice/\hspace{0pt}test/\hspace{0pt}image_\hspace{0pt}no_tag.png fájlt. | A bal alsó sarokban megjelenik egy "No tags have been found" hiba, a kalibrációs kép nem változik meg. |
| Túl nagy kalibrációs kép | Szoba megnyitva, kalibrálási állapotban | Kattintson az "Upload calibration image" gombra, majd töltsön fel egy 16 MiB-nál nagyobb fájlt (lásd: -@sec:large-file. fejezet) | A bal alsó sarokban megjelenik egy "File too large" hiba, a kalibrációs kép nem változik meg |
| Sikeres kalibrálás | Szoba megnyitva, kalibrálási állapotban, kalibrációs kép nélkül. Másik eszközön szoba megnyitva, megjelenítő módban | Készítsen egy képet, ahol a megjelenítő kliens kalibráló jele jól látszik. Kattintson az "Upload calibration image" gombra, majd töltse fel ezt a képet. | A kalibrálási kép megjelenik, rajta csak és kizárólag a megjelenítő kliens kijelzője látszik. |
| Sikeres kalibrálás, kalibrációs kép megváltoztatásával | Szoba megnyitva, kalibrálási állapotban, fel van töltve kalibrációs kép. Másik eszközön szoba megnyitva, megjelenítő módban | Lépjen be egy új eszközön a szobába, megjelenítéső módban. Készítsen egy képet, ahol az új megjelenítő kliens kalibráló jele jól látszik. Kattintson az "Upload calibration image" gombra, majd töltse fel ezt a képet. | A kalibrálási kép megváltozik, rajta csak és kizárólag az új megjelenítő kliens kijelzője látszik. |
| Kalibrációs kép szinkronizálás | Egyes eszközön szoba megnyitva, kalibrálási állapotban, nincs feltöltve kalibrációs kép. Kettes eszközön szoba megnyitva, konfiguráló módban. Hármas eszközön szoba megnyitva, megjelenítő módban. | Készítsen egy képet, ahol az hármas kliens kalibráló jele jól látszik. Az egyes kliensen kattintson az "Upload calibration image" gombra, majd töltse fel az előbb készített képet. | A kép sikeresen feltöltődik, és megjelenik a kettes eszközön is. |
| Közvetítés, kalibrációs képpel | Szoba megnyitva, kalibrálási állapotban, kalibrációs kép fel van töltve | Kattintson a "Broadcast" gombra | Megjelenik a közvetítési oldal |
| Közvetítés állapotváltozás szinkronizálás | Szoba megnyitva, kalibrálási állapotban, kalibrációs kép fel van töltve. Másik eszközön szoba megnyitva, konfiguráló módban. | Kattintson a "Broadcast" gombra | Megjelenik a közvetítési oldal a másik eszközön is |
| Kalibrálás állapotváltozás | Szoba megnyitva, közvetítési állapotban | Kattintson a "Calibrate" gombra | Megjelenik a kalibrálási oldal |
| Kalibrálás állapotváltozás szinkronizálás | Szoba megnyitva, közvetítési állapotban. Másik eszközön szoba megnyitva, konfiguráló módban. | Kattintson a "Calibrate" gombra | Megjelenik a kalibrálási oldal a másik eszközön is |
| Fénykép feltöltése | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. Másik eszközön szoba megnyitva, szintén konfiguráló módban. "Photos" médiatartalom típus kiválasztva. | Kattintson az "Upload photo" gombra és töltsön fel egy képet, például az apriltagservice/\hspace{0pt}test/\hspace{0pt}image_no_tag.png fájlt. | A kép megjelenik a listában, a helyes indexképpel és a helyes fájlnévvel. A kép szintén megjelenik a másik eszközön. |
| Hibás kiterjesztésű fénykép feltöltés | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "Photos" médiatartalom típus kiválasztva. | Kattintson az "Upload photo" gombra és töltse fel a `README.md` fájlt. | A bal alsó sarokban megjelenik egy "Invalid extension" hiba, a lista nem változik meg. |
| Túl nagy fénykép feltöltés | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "Photos" médiatartalom típus kiválasztva. | Kattintson az "Upload photo" gombra és töltsön fel egy 16 MiB-nál nagyobb fájlt (lásd: -@sec:large-file. fejezet) | A bal alsó sarokban megjelenik egy "File too large." hiba, a lista nem változik meg. |
| Fénykép kiválasztása | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "Photos" médiatartalom típus kiválasztva, legalább egy kép feltöltve. Másik eszközön szoba megnyitva, megjelenítő módban. | Kattintson az egyik feltöltött képre. | A bal oldali előnézeten megjelenik a kiválasztott kép. A kép szintén megjelenik a megjelenítő kliensen. |
| iFrame hibásan formázott URL-el | Szoba megnyitva, közvetítési állapotban, konfiguráló modban. "IFrame" médiatartalom típus kiválasztva. | Írja be az "Embed url" mezőbe a következő karakterláncot: "Lorem ipsum dolor sit amet". Kattintson a "Play" gombra. | Nem történik semmi. |
| iFrame helyes URL-el | Szoba megnyitva, közvetítési állapotban, konfiguráló modban. "IFrame" médiatartalom típus kiválasztva. Másik eszközön szoba megnyitva, megjelenítő módban. | Írja be az "Embed url" mezőbe egy beágyazható oldal URL-jét^[Például: https://www.youtube.com/embed/dQw4w9WgXcQ]. Kattintson a "Play" gombra. | A jobb oldali előnézeten megjelenik a beágyazás. A beágyazás szintén megjelenik a megjelenítő kliensen. |
| Videó hibásan formázott URL-el | Szoba megnyitva, közvetítési állapotban, konfiguráló modban. "Video" médiatartalom típus kiválasztva. | Írja be az "Embed url" mezőbe a következő karakterláncot: "Lorem ipsum dolor sit amet". Kattintson a "Play" gombra. | "Invalid url" hiba. A megjelenített tartalom nem változik. |
| Videó nem engedélyezett URL-el | Szoba megnyitva, közvetítési állapotban, konfiguráló modban. "Video" médiatartalom típus kiválasztva. | Írja be az "Embed url" mezőbe a következő karakterláncot: "http://google.com". Kattintson a "Play" gombra. | "Unsupported URL" hiba. A megjelenített tartalom nem változik. |
| Videó sikeres betöltése | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. Másik eszközön szoba megnyitva, megjelenítő módban. "Video" médiatartalom típus kiválasztva. | Írjon be az "Embed url" mezőbe egy helyes YouTube linket^[Például: https://www.youtube.com/watch?v=dQw4w9WgXcQ]. Kattintson a Play gombra | A jobb oldali előnézeten megjelenik a videó. A videó szintén megjelenik a megjelenítő kliensen. A videó alapértelmezetten szüneteltetve van, egy Play gomb jelenik meg az előnézet alatt. |
| Videó indítása | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. Videó betöltve, szüneteltetve | Kattintson az előnézet alatti Play gombra. | A videó mindegyik kliensen elindul. |
| Videó szüneteltetése | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. Videó betöltve, elindítva | Kattintson az előnézet alatti Pause gombra. | A videó mindegyik kliensen megállt, illetve a lejátszás ideje szinkronizálódik. |
| Videó indítása, szinkronizálva | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. Videó betöltve, szüneteltetve, mindegyik kliensen legalább egyszer elindítva | Kattintson az előnézet alatti Play gombra. | A videó mindegyik kliensen elindul, illetve a lejátszás ideje szinkronizálódik. |

### Nagy fájlok létrehozása {#sec:large-file}

Linuxon a következő paranccsal hozhat létre egy 32 MiB fájlt:

```sh
dd if=/dev/urandom of=large.png bs=32MiB count=1
```

Más operációs rendszereken legegyszerűbben egy online eszköz segítségével hozhatja létre ezt a fájlt. A PineTools random fájl generálója[@pinetools] elérhető a következő oldalon: https://pinetools.com/random-file-generator. A fájl méretét állítsa be 32 MB-ra, a fájlnevet az "Other" opció segítségével egy `.png` kiterjesztésű névre. Kattintson a "GENERATE!" gombra, majd töltse le a generált fájlt.

# Irodalomjegyzék
