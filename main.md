---
numbersections: true
---

# Bevezetés

A mai világban körbevesznek minket a számítógépek. A zsebünkben lévő okostelefontól kezdve, a nappalinkban lévő televízión és számítógépen át, egészen a bolti vásárlásainkat segítő kioszkokig<!-- Ez a hivatalos magyar neve? Also, magyarázat? -->. Egyes kutatások szerint, egy személynek átlagosan **3,6** okos eszköze van<!-- Forrás! Mikori a kutatás? Csak a kijelzővel rendelkező eszközök relevánsak, de az lelőné a projekt célját. -->. Ezeknek az eszközönek viszont<!--ez így magyaros?--> a lehetőségeit korlátozza, hogy eredendően számítási és I/O kapacitása megoszlik. <!--Kivágva: A mai okostelefonok memóriája nagyobb, mint egyes laptopoké, és a kijelzőjük is jobb, mint a legtöbb monitor. Ennek ellenére vannak olyan --> Ezeknek a problémáknak a feloldására több megoldás is létezik, mind számítási<!--pl. Slurm, Spark etc. HPC-->, mind bemeneti oldalról<!--KVM-ek, Synergy és open source társai-->, de a kimeneti kérdésre kevesebb megoldás létezik.<!--Azért jó lenne egy-kettőt megemlíteni.-->

Szakdolgozatom egy interaktív webes alkalmazás, ami ezt az űrt hivatott betölteni<!--Ez így van elég hivatalos?-->. Segítségével bármennyi webböngészésre képes eszköz kijelzőjét fel tudjuk használni egy kijelzőként. Ezeket az egyesített kijelzőket (továbbiakban virtuális kijelzőket<!--Szójegyzék-->) használhatjuk különböző médiatartalmak megjelenítésére, például képek, videók, prezentációk.

# Felhasználói dokumentáció {#sec:userdocs}

Az alkalmazás központilag kiszolgálva elérhető a https://getcrossview.com címen.

## Sajátkezű kiszolgálás

Ha az alkalmazást saját szerverről szeretnénk kiszolgálni, akkor a Docker Compose alapú telepítés javasolt.

Az alapértelmezett konfiguráció egy szerverről szolgálja ki az összes szolgáltatást, melyeket egy proxy segítségével kapcsol össze. Ehhez szükséges, hogy a szolgáltatásoknak legyenek létrehozva a megfelelő aldomainek, amelyek mind a szerverre mutatnak.

A szükséges domainek (zárójelben a központilag kiszolgált domainek)

- A fő alkalmazás domainje (`getcrossview.com`/`www.getcrossview.com`)
- A Minio (S3 tárhely) domainje (`minio.getcrossview.com`)
- A Minio műszerfal domainje (`dashboard.getcrossview.com`)

Lokális futtatás esetén elég a HOSTS fájl szerkesztése. Erről több információt a -@sec:hosts fejezetben találhat.

1. Telepítse fel a Docker-t. Ehhez elérhető segédletet a [docker.com](https://docs.docker.com/engine/install/) oldalon találhat.
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

3. Módosítsa az nginx konfigurációt (`nginx.prod.conf`).
   Állítsa át a `server_name` kezdetű sorokat úgy, hogy a szolgáltatások az ön által megadott domaint szolgálják ki.
4. Indítsa el a szolgáltatásokat a `docker compose -f docker-compose.prod.yml up` paranccsal
5. Konfigurálja a Minio-t
   1. Menjen fel a Minio műszerfal oldalára, és lépjen be a `minio.env`-ben megadott adatokkal.
   2. Állítsa be a régiót a Configuration->Region oldalon. Legyen `us-east-1`
   3. A buckets oldalon hozzon létre két vödröt:
      - `calibrations`
      - `media`
   4. Állítsa be a vödröknek, hogy publikosan olvashatóak legyenek
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

Az alkalmazást megnyitva a főoldalt láthatjuk (-@fig:main). Ezen az oldalon tudunk új szobát<!--szoba kiemelése. Szójegyzék?--> létrehozni, vagy egy már létező szobához csatlakozni. Minden szobához tartozik egy 8 karakter hosszú kód, ami azt a szobát egyedileg azonosítja. Ez a kód a szobák bal felső sarkában látható.

![A főoldal](images/main.png){#fig:main}

A szobák nézete két fő dologtól függ: a szoba **állapotától**, és a kliens **szerepétől**.

A szobákban lévő klienseknek két lehetséges **szerepe** van:

- Konfiguráló

  Ezek a kliensek felelnek a médiatartalmak kiválasztásáért, illetve a kijelzők helyzetének kalibrálásáért.

- Megjelenítő

  Ezeknek a klienseknek feladata, hogy a jelenleg megjelenítendő médiatartalomnak megjelenítsék azt a részét, amit az adott klienshez rendeltünk a kalibrálás során.

Egy konfiguráló kliensből megjelenítő klienst lehet csinálni a jobb felső sarokban lévő `View` gomb kattintásával.

A szobáknak két lehetséges **állapota** van:

- Kalibrálás

  Ebben az állapotban minden megjelenítő kliensen egy kalibrációs jel jelenik meg. A konfiguráló kliensek feltölthetnek egy, a megjelenítő kliensekről készített fényképet (kalibráló képet<!--glossary-->).

- Közvetítés

  Ebben az állapotban tudnak a konfiguráló kliensek médiatartalmakat kiválasztani, amiket a megjelenítő kliensek megjelenítenek. Ebbe az állapotba csak akkor lehet eljutni, ha kalibráló kép feldolgozása sikeres volt.

A két állapot között a konfiguráló kliensek tudnak váltani, az alkalmazás tetején levő gombpárral.

### Kalibrálási állapot használata

Ahhoz, hogy minden kijelző síkbeli elhelyezkedését tudjuk, szükséges egy kalibrációs lépés.

A kalibrálás során a felhasználó előkészítheti a megjelenítő klienseket. A legjobb eredmény elérésének érdekében próbáljuk meg az összes kijelzőt egy síkba helyezni.

A megjelenítő klienseken egy kalibráló kód jelenik meg a jobb oldalon, illetve a bal oldalon a szoba kódja és a kliens egyedi sorszáma (-@fig:apriltag).

![Megjelenítő kliens a kalibrálási állapotban.](images/apriltag.png){#fig:apriltag width=50%}

A konfigurációs kliens ebben az állapotban egy `Upload calibration image` (`Kalibrációs kép feltöltése`) gombot lát és a legutóbb feltöltött kalibrációs képet (-@fig:calibrationbefore).

![Konfiguráló kliens a kalibrálási állapotban.](images/calibration-before.png){#fig:calibrationbefore width=50%}

A felhasználónak egy fényképet kell készítenie a megjelenítő kliensekről. Ez lesz a **kalibrációs kép**. A kalibrációs kép kiterjesztése a következők egyike legyen: `.png, .jfif, .jpeg, .jpg, .webp, .avif, .heic, .heif`. Fontos, hogy a kalibrációs képen mindegyik klienshez tartozó kalibrációs jel teljesen látszódjon, ugyanakkor a kijelzők többi része elhagyható a fényképről. A legjobb eredmény elérésének érdekében a fényképet nagyjából abból a szemszögből készítsük, ahonnan a virtuális kijelzőt nézni szeretnénk.

A fénykép feltöltése és a sikeres kalibrálás után megjelenik a kalibrációs kép, méretre vágva. A fénykép szürkeárnyalatosan jelenik meg, viszont a felismert kijelzők a hozzájuk tartozó színnel lesznek kiemelve (-@fig:calibrationafter).

![Konfiguráló kliens a kalibrálási állapotban, sikeres kalibrálás után.](images/calibration-after.png){#fig:calibrationafter width=50%}

Sikeres kalibrálás után elérhetővé válik a `Broadcast` gomb, amivel áttérhetünk a közvetítési állapotba.

### Közvetítési állapot használata

A médiatartalmak elindítását és előnézetét a közvetítési állapotban lehet megtenni.

A közvetítési állapotban a megjelenítő kliensek csak a virtuális kijelző tartalmát jelenítik meg.

A konfiguráló kliensnek lehetősége van médiatartalmak típusát kiválasztani, a médiatartalmat kiválasztani, és a típustól függően feltölteni.

Bal oldalon található a típus kiválasztó **(1)**, tőle jobbra az adott típus konfigurációs panelje **(2)**, majd a jobb oldalon egy előnézet **(3)**. Az előnézet alatt opcionálisan megjelenhetnek az adott típushoz tartozó vezérlők is **(4)**.

![A konfiguráló kliens nézete a közvetítési állapotban](images/broadcast.png){width=50%}

Jelenleg két médiatartalom típus elérhető:<!--TODO: Ha lesz több médiatípus, ezt kibővíteni-->

- Fénykép
- Videó
- iFrame

#### Fényképek közvetítése

A bal sávon válasszuk ki a "Photos" lehetőséget. Ezzel láthatóvá válik a fénykép kezelő panel. Itt tudunk feltölteni képeket, illetve már feltöltött képeket "kiküldeni" a virtuális kijelzőre.

Ennek a típusnak nincsenek vezérlői.

#### Videók közvetítése

A bal sávon válasszuk ki a "Videos" lehetőséget. Ezzel láthatóvá válik a videó kezelő panel. Itt meg tudunk adni egy videó elérési címét, amit megjeleníthetünk a virtuális kijelzőn.

A cím lehet YouTube videóra mutató URL, vagy saját platformról kiszolgált tartalom. <!-- Biztos hogy engedünk custom kiszolgálót? Also, ide be lehetne írni, hogy a library mit supportál még. -->

A videó médiatartalom típus elérhetővé tesz egy vezérlő gombot is: a szünet/lejátszát (pause/play) gombot.

#### iFrame közvetítés (haladó)

Az alkalmazásban elérhető egy **haladóknak szánt** iFrame opció is. Ezzel egy tetszőleges weboldalt lehet megjeleníteni a virtuális kijelzőn. Fontos, hogy ez az opció nem hajt végre szinkronizálást a kliensek között <!-- Ide be kéne majd linkelni a részletes működési leírást, maybe -->, illetve csak olyan weboldalakkal működik, amelyek engedik az iFrame beágyazást.

Egy egyszerű példa a https://vdo.ninja szolgáltatás használata, egy _kijelző képének megosztására_.

1. Menjünk fel a https://vdo.ninja oldalra.
2. Válasszuk ki a "Remote Screenshare into OBS" lehetőséget
3. Válasszuk ki a megosztani kívánt kijelzőt
4. Másoljuk ki az oldal tetején található `https://vdo.ninja/?view/??????` linket a mellette lévő 📎 gomb segítségével.
5. Menjünk át a CrossView szobánkba, ami már be van állítva Közvetítési állapotra
6. Válasszuk ki az iFrame médiatartalom típust
7. Másoljuk be az elöbbi linket
8. Adjuk hozzá a következő tagot: `&na` (ez kikapcsolja a hangot, ezzel engedélyezve az automatikus lejátszást)

A [vdo.ninja](https://vdo.ninja) szolgáltatást több más dologra is lehet használni, például webkamerák megosztására, [Android illetve iOS eszközökről való közvetítésre](https://docs.vdo.ninja/steves-helper-apps/native-mobile-app-versions) (natív alkalmazások segítségével), vagy akár az [OBS nevű szoftverből közvetíteni](https://docs.vdo.ninja/guides/from-obs-to-vdo.ninja-using-whip)<!--reference-->.

A vdo.ninja további lehetőségeiről a [dokumentációjában](https://docs.vdo.ninja/) lehet olvasni.

# Fejlesztői dokumentáció

A projekt magja a "Main Service" nevű React alapú full-stack alkalmazás. Ez implementálja mind a backend, mind a frontend funkcionalitást.

A kalibráláshoz készült egy "Apriltag Service" nevű Pythonos komponens is, ami egy microservice-ként funkcionál, és a kalibrálási jelek felismerését, illetve egyes kalibráláshoz kapcsolódó matematikai számításokat hajt végre.

Külső fejlesztésű szolgáltatásként van használva a Redis mint adatbázis, és a Minio mint S3 kompatibilis tárhely.

## Quick Start

A fejlesztői környezet ugyan telepítése hasonló a prod környezetéhez. A főbb különbség, hogy a `docker-compose.prod.yml` és az `nginx.prod.conf` helyett a `docker-compose.dev.yml` és az `nginx.dev.conf` fájlokat kell módosítani.

1. Telepítse fel a Docker-t. Ehhez elérhető segédletet a [docker.com](https://docs.docker.com/engine/install/) oldalon találhat.
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

3. Módosítsa az nginx konfigurációt (`nginx.dev.conf`).
   Állítsa át a `server_name` kezdetű sorokat úgy, hogy a szolgáltatások az ön által megadott domaint szolgálják ki.
4. Indítsa el a szolgáltatásokat a `docker compose -f docker-compose.dev.yml up` paranccsal
5. Konfigurálja a Minio-t
   1. Menjen fel a Minio műszerfal oldalára, és lépjen be a `minio.env`-ben megadott adatokkal.
   2. Állítsa be a régiót a Configuration->Region oldalon. Legyen `us-east-1`
   3. A buckets oldalon hozzon létre két vödröt:
      - `calibrations`
      - `media`
   4. Állítsa be a vödröknek, hogy publikosan olvashatóak legyenek
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

Lokális tesztelés esetén hasznos lehet, ha nem kell egy kulső domaint használni. Ennek a legegyszerűbb módszere egy HOSTS fájl létrehozása.

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

Ennek a fejezetnek az elolvasása előtt érdemes elolvasni a -@sec:userdocs (felhasználói dokumentáció) fejezetet.

Az alkalmazás szobákra van osztva, amelyek egymástól függetlenül működnek. Minden szoba 24 óráig elérhető.

A szobáknak van egy azonosítója, amely egy szekvenciális sorszámból van generálva egy determinisztikus algoritmussal (lásd: -@sec:roomcode ). Ez biztosítja, hogy egyszerre két szoba nem kaphatja meg ugyan azt a kódot.

Minden szobához tartozhat egy kalibrációs kép, amely a legutóbb feltöltött kalibráció szerint készül. Kalibrációs állapotba csak akkor lehet áttérni, ha van ilyen kép. Ezen felül minden szobához tartozhatnak feltöltött fényképek, amelyeket a közvetítési állapotban lehet használni.

Minden megjelenítő kliensnek van egy egyedi azonosító sorszáma. Ez a sorszám az elérésiútban tárolódik el. A megjelenített kalibráló jel (Apriltag <!--ref-->) sorszáma megegyezik a kliens sorszámával.

A kalibráció során a képen az Apriltag Service megkeresi az összes kalibráló jelet, majd az azokból megtalált homográfiákból<!--ref--> és a jelek elhelyezkedéséből létrehoz egy egész kijelzős homográfiát, és egy virtuális koordinátarendszerbe helyezi őket.

Közvetítési állapotba érve a megjelenítő kliensek a hozzájuk tartozó homográfiát használva egy `div`-re CSS `transform`-ot helyez (`ScreenContent`). Ez a `transform` vetíti ki a `div` tartalmát a megjelenítő kliens kijelzőjére úgy, hogy a kijelzők egy koherens képet alkossanak.

A homográfiák létrehozásáról további információ a <!--TODO: Add reference to matrices chaper--> fejezetben található.

A `ScreenContent` komponens a szoba jelenlegi adatai szerint töltődik fel a megfelelő tartalommal. Mivel a vetítést a CSS `transform` végzi, ezért ennek a komponensnek nem kell foglalkoznia vele, csak a szinkronizálást kell implementálnia, ahol lehet (pl. videó jelenlegi timestampjének szinkronizálása a kliensek között).

## Adatbázis

A projekthez a Redis adatbázis szoftvert használtam. A Redis egy kulcs-érték adatbázis, ahol minden elérhető rögtön a memóriából, ezért gyakran használják például gyorsítótárakhoz.

A Redis több szempontból is előnyös ehhez a projekthez:

- gyors, hiszen minden memóriában van tárolva
- mivel nincs huzamosabb ideig tárolt adat, ezért a memóriaigény alacsony
- az adatok struktúrálatlanok, így nincs előnye az adatok táblákba rendezésének
- beépített támogatás az alkalmazáson belüli üzenetküldésre (ezzel megkönnyítve a valós idejű adatszolgáltatást)

Természetesen ez a választás hátrányokkal is járt:

- a kulcs-érték felépítés miatt nincs széleskörű ORM támogatás, az adatbázishoz tartozó boilerplate kódod sajátkezűleg kell megírni
- a JSON szerű adatbázisokhoz képest (pl. MongoDB) a Redis egy flat struktúrában tárolja az adatokat. Ennek hátránya, hogy hierarchikus adatok tárolására csak jól meggondolt kulcsokkal van lehetőség.

  Például: `room:ROOMID:photos:PHOTOUUID:path`. Természetesen azért, hogy az SQL injection-re hajazó problémákat elkerüljük, szükséges, hogy a kulcs dinamikusan megadható tagjai validálva legyenek. Egy `:`-ot tartalmazó ROOMID könnyen problémákat okozhat a kódban.

### Adatbázis séma

Az alábbiakban a szoftver különböző komponenseiben használt Redis kulcsok találhatóak.

A kulcsban `NAGY BETŰVEL` vannak jelölve a dinamikusan beillesztendő tagok:

- `ROOM`: a szoba kódja
- `SCREEN`: a megjelenítő kliens sorszáma
- `PHOTO`: a szobába feltöltött egyik fénykép UUID-je

#### Szoba-szintű adatbázis elemek

| Kulcs              | Típus           | Leírás                                                                                                                                                                                                                                                                                                 |
| ------------------ | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `roomCount`        | Szám            | A létrehozott szobák számát tárolja. Értelmezhető úgy is, mint a legutoljára létrehozott szoba sorszáma.                                                                                                                                                                                               |
| `room:ROOM`        | PubSub csatorna | Ezzel a kulccsal nem létezik kulcs-érték páros. Ez a kulcs a [Pub/Sub](https://redis.io/docs/latest/develop/interact/pubsub/) üzeneteknek van fenntartva. Jelenleg csak a `ping` string küldhető el rajta. További információ: <!--TODO: ide rakni egy referenciát a Main Service-es PubSub részre --> |
| `room:ROOM:mode`   | string          | A szoba jelenlegi állapota. Értéke csak `calibration` (kalibrálás) vagy `viewing` (közvetítés) lehet.                                                                                                                                                                                                  |
| `room:ROOM:image`  | string          | A szoba jelenlegi kalibrációs képének S3-beli neve, kiterjesztéssel együtt.                                                                                                                                                                                                                            |
| `room:ROOM:width`  | Szám            | A szoba jelenlegi kalibrációs képének szélessége pixelben.                                                                                                                                                                                                                                             |
| `room:ROOM:height` | Szám            | A szoba jelenlegi kalibrációs képének magassága pixelben.                                                                                                                                                                                                                                              |

##### Szoba kód generálása {#sec:roomcode}

Új szoba létrehozásakor a roomCount-ból szükséges létrehozni egy szoba kódot. Ehhez a LCG random szám algoritmus bijektív tulajdonságait használom ki. <!-- Kéne valami reliable source ezekre a tulajdonságokra. --> Ezt a következő kódrészlet implementálja a `mainservice/src/lib/utils.ts` fájlban:

<!--TODO: Kitalálni, hogy az a függvény akkor most valójában mit is csinál manapság. Illetve esetleg matematikailag felírni.-->

```typescript
export function keyToCode(key: number, length = CODE_LENGTH) {
  // This function uses the bijective
  // properties of LCG random number generators
  // to obfuscate the key
  const a = BigInt(214013);
  const c = BigInt(2531011);

  const bigkey = BigInt(key);

  // https://math.stackexchange.com/a/2115780
  const modulo = BigInt(CODE_ALPHABET.length) ** BigInt(length);
  const apowkey = powmod(a, bigkey, modulo);
  let num = (apowkey + ((apowkey - 1n) / (a - 1n)) * c) % modulo;
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
| ----- | ----- | ------ |
| `room:ROOM:screenCount` | Szám | Egy szobához tartozó megjelenítő kliensek száma |
| `room:ROOM:available` | Szám halmaz | Egy szobához tartozó jelenleg elérhető megjelenítő kliensek sorszámának halmaza |
| `room:ROOM:screen:SCREEN:config` | JSON string - `{width: number, height: number, x: number, y: number}` | A megjelenítő kliensek kalibráló jelének helye és mérete a kijelzőn. Jelenleg ez pontosan a képernyő jobb fele |
| `room:ROOM:screen:SCREEN:ping` | Szám | Mindig `1`. Az [EXPIRE](https://redis.io/docs/latest/commands/expire/) értéke 2 percre van beállítva, és a kliensek 30 másodpercenként újra létrehozzák. Ezzel lehet észlelni kliens timeout-ot. Lásd: -@sec:timeout |
| `room:ROOM:screen:SCREEN:homography` | JSON string - 3x3-as szám mátrix | Az Apriltag Service által generált homográfia. Lásd: <!--Mátrixos fejezet referencia--> |

##### Megjelenítő kliens timeout {#sec:timeout}

Egyes esetekben nem lehet egyértelműen eldönteni, hogy a megjelenítő kliens mikor csatlakozott le. Ennek az észlelésére van beépítve egy pingelő rendszer az alkalmazásba. A kliens 30 másodpercenként hívja meg a `sendPing` szerveroldali függvényt, amely a `room:ROOM:screen:SCREEN:ping` kulcsó értéket `1`-re állítja, 2 perces EXPIRE értékkel. Így a kulcs nem fog eltűnni, amíg létezik a megjelenítő kliens. 

A kulcs eltűnését egy [keyspace notification](https://redis.io/docs/latest/develop/use/keyspace-notifications/) segítségével vesszük észre. 

```ts
// A ping kulcs-ot matchelő regex
const screenKeyRegex = /^room:([^:]+):screen:(\d+):ping$/;

export async function setupScreenExpiry(redis: RedisClientType) {
  // keyspace notification-ök bekapcsolása "Keyevent, expire" módban
  await redis.configSet("notify-keyspace-events", "Ex");
  // Új Redis kliens létrehozása, mivel subscribe mellett más művelet nem hajtható végre
  const listener = redis.duplicate();
  await listener.connect();

  // Ez az event meghívódik bármilyen kulcs lejártakor
  void listener.subscribe("__keyevent@0__:expired", (key) => {
    // Ha a kulcs az egy kijelző timeouthoz tartozik, akkor hívja le a deregisterScreen függvényt az adott kijelzőn
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

Jelenleg a `deregisterScreen` függvény nem csinál semmit.

#### Jelenlegi közvetítéshez tartozó adatbázis elemek

| Kulcs | Típus | Leírás |
| ----- | ----- | ------ |
| `room:ROOM:content:type` | String ( `none` \| `photo` \| `video` \| `iframe` ) | A jelenlegi tartalom típusa. `none` ha nincs kiválasztva tartalom típus |
| `room:ROOM:content:url` | String | Fénykép médiatípus esetén a tartalom neve a media vödörben. Videó és iFrame esetén a tartalom teljes URL-je. |
| `room:ROOM:content:status:type` | String (`paused` \| `playing`) | Videó tartalom esetén a lejátszás jelenlegi állapota |
| `room:ROOM:content:status:timestamp` | Szám | Videó tartalom esetén a lejátszás állapotának megváltoztatási ideje, UNIX idő milliszekundumban |
| `room:ROOM:content:status:videotime` | Szám | Videó tartalom esetén használatos. A videó ideje másodpercbe, a videó lejátszási állapot megváltozásának pillanatában |

#### Feltöltött fényképekhez tartozó adatbázis elemek

| Kulcs | Típus | Leírás |
| ----- | ----- | ------ |
| `room:ROOM:photos` | String halmaz | A szobába feltöltött fényképek UUID azonosítóját tartalmazó halmaz |
| `room:ROOM:photos:PHOTO:name` | String | A UUID-hoz tartozó fénykép eredeti fájlneve |
| `room:ROOM:photos:PHOTO:path` | String | A UUID-hoz tartozó fénykép fájlneve a media vödörben |

## Fájl tárolás

A fájlok tárolására egy S3 kompatibilis tárhely szolgáltatást használok. Ez a tárhely szolgáltatás alapértelmezetten a Minio, hiszen jól támogatott és széleskörűen használt<!--citation-->. Természetesen bármilyen más S3 kompatibilis szolgáltatással le lehetne cserélni.

Az alkalmazás két S3 bucket-et (vödröt) használ:

- calibration

  Ide kerülnek a kalibrációs képek, illetve a perspektíva korregált változataik
- media

  Ide kerülnek a megjelenítésre feltöltött fényképek

A `main.env`-ben megadott S3 felhasználónak mindkét vödörhöz kell, hogy kapjon írási és olvasási jogot is.

A vödröknek olvashatónak (de nem feltétlenül listázhatónak) kell lenniük vendégfelhasználók által is. A telepítési útmutatóban található policy ezt állítja be.

Az S3 protokol engedélyez úgynevezett "pre-signed"<!--link--> URL létrehozását. A pre-signed URL-t egy privilegizált felhasználó tud létrehozni, előre kitöltött adatokkal. Ekkor a URL a privilegizált felhasználó jogait veszi át.

Pre-signed URL-ek két helyen vannak használatban az alkalmazásban:

- A kalibráló kép/fénykép feltöltésekor

  A szerver létrehozza a pre-signed URL-t a saját S3 felhasználójával, melyben megköti a vödröt, a fájl nevét, illetve a `Content-Length` headert. Így a kliens S3 vendégfelhasználóként is képes lesz írni a fájlt. A szerver le tudja ellenőrizni a klienstől kapott méret segítségével, hogy a fájl mérete nem halad-e meg egy limitet, majd a `Content-Length` megkötés biztosítja, hogy a kliens a megfelelő méretű adatot töltte fel.
- A kalibrálás utáni perspektíva korregált kalibráló kép feltöltése

  A perspektíva korrekciót az Apriltag Service végzi, de nincs hozzáférése privilegizált S3 felhasználóhoz. Ahhoz, hogy mégis fel tudja tölteni a képet, kalibrálás előtt a szerver létrehoz neki egy pre-signed URL-t erre a célra.

## Main service

<!-- react, t3 stack, full stack -->

<!-- pathek -->

<!-- serialization, pubsub (trpc) -->

<!-- Fájlfeltöltés folyamata -->

<!-- médiatípusok ismertetése, új médiatípusok hozzáadásának folyamata -->

## Kalibrálás

### Kalibrálási szolgáltatás

A kijelzők helyének pontos megállapításához szükséges egy kalibrálási fázis. Ehhez Apriltag<!--ref-->-eket használunk, amiknek gyorsan és pontosan <!--citation-->meg tudják határozni a sarkainak helyzetét. 

Mivel a legtöbb számítógépes látás könyvtár és eszköz Python-ban érhető el, ezért ezt a lépést egy külön szolgáltatásban hajtom végre, melyet Apriltag Service-nek hívok. A következő könyvtárakat használom: 

- Az Apriltagek feldolgozására a `pupil-apriltags` könyvtárat
- A fényképek megnyitására, mentésére, perspektíva korrigálására az opencv könyvtárat (`opencv-python-headless`).
- Az egyéb mátrixos számításokhoz a `numpy` könyvtárat
- A Main Service-el való kommunikálás segítéséhez a FastAPI keretrendszert

Számítógépes látásban a különböző síkok közötti perspektív transzformációkat egy homográfia mátrixal lehet jellemezni. Az Apriltag könyvtár egy ilyen homográfiát ad vissza minden kalibrációs jelhez, ami az Apriltag saját koordináta-rendszeréből képez a fénykép koordináta-rendszerébe. Ezt kombinálva egy saját homográfiával, ami a megjelenítő kliens koordináta-rendszeréből (lásd: `room:ROOM:screen:SCREEN:config` ) képez az Apriltag koordináta-rendszerébe, kapunk egy homográfiát ami a kliens kijelzőjét jellemzi a fénykép keretein belül. Ez után a kliensek közül kiválasztunk egy "fő kijelzőt" (ez a legkisebb sorszámú kliens jelenleg), és arra ortogonálisan létrehozunk egy olyan koordináta-rendszert, amelybe belefér az összes kliens kijelzője. Így jön létre a virtuális kijelző.

### Kalibrálási folyamat

<!-- End to end mátrixok -->

<!-- Hasznos kód részletek -->

## Tesztek

<!-- TODO: Tesztek -->

# Összegzés

# Irodalomjegyzék
