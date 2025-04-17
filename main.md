---
numbersections: true
---

# Bevezetés

A mai világban körbevesznek minket a számítógépek. A zsebünkben lévő okostelefontól kezdve, a nappalinkban lévő televízión és számítógépen át, egészen a bolti vásárlásainkat segítő kioszkokig<!-- Ez a hivatalos magyar neve? Also, magyarázat? -->. Egyes kutatások szerint, egy személynek átlagosan **3,6** okos eszköze van<!-- Forrás! Mikori a kutatás? Csak a kijelzővel rendelkező eszközök relevánsak, de az lelőné a projekt célját. -->. Ezeknek az eszközönek viszont<!--ez így magyaros?--> a lehetőségeit korlátozza, hogy eredendően számítási és I/O kapacitása megoszlik. <!--Kivágva: A mai okostelefonok memóriája nagyobb, mint egyes laptopoké, és a kijelzőjük is jobb, mint a legtöbb monitor. Ennek ellenére vannak olyan --> Ezeknek a problémáknak a feloldására több megoldás is létezik, mind számítási<!--pl. Slurm, Spark etc. HPC-->, mind bemeneti oldalról<!--KVM-ek, Synergy és open source társai-->, de a kimeneti kérdésre kevesebb megoldás létezik.<!--Azért jó lenne egy-kettőt megemlíteni.-->

Szakdolgozatom egy interaktív webes alkalmazás, ami ezt az űrt hivatott betölteni<!--Ez így van elég hivatalos?-->. Segítségével bármennyi webböngészésre képes eszköz kijelzőjét fel tudjuk használni egy kijelzőként. Ezeket az egyesített kijelzőket (továbbiakban virtuális kijelzőket<!--Szójegyzék-->) használhatjuk különböző médiatartalmak megjelenítésére, például képek, videók, prezentációk.

# Felhasználói dokumentáció

Az alkalmazás központilag kiszolgálva elérhető a https://getcrossview.com címen.

## Sajátkezű kiszolgálás

Ha az alkalmazást saját szerverről szeretnénk kiszolgálni, akkor a Docker Compose alapú telepítés javasolt.

Az alapértelmezett konfiguráció egy szerverről szolgálja ki az összes szolgáltatást, melyeket egy proxy segítségével kapcsol össze. Ehhez szükséges, hogy a szolgáltatásoknak legyenek létrehozva a megfelelő aldomainek, amelyek mind a szerverre mutatnak.

A szükséges domainek (zárójelben a központilag kiszolgált domainek)

- A fő alkalmazás domainje (`getcrossview.com`/`www.getcrossview.com`)
- A Minio (S3 tárhely) domainje (`minio.getcrossview.com`)
- A Minio műszerfal domainje (`dashboard.getcrossview.com`)

Lokális futtatás esetén elég a HOSTS fájl szerkesztése. Erről több információt a <!--TODO: Írni erről is egy fejezetet --> fejezetben találhat.

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

#### Fényképek közvetítése

A bal sávon válasszuk ki a "Photos" lehetőséget. Ezzel láthatóvá válik a fénykép kezelő panel. Itt tudunk feltölteni képeket, illetve már feltöltött képeket "kiküldeni" a virtuális kijelzőre.

Ennek a típusnak nincsenek vezérlői.

#### Videók közvetítése

A bal sávon válasszuk ki a "Videos" lehetőséget. Ezzel láthatóvá válik a videó kezelő panel. Itt meg tudunk adni egy videó elérési címét, amit megjeleníthetünk a virtuális kijelzőn.

A cím lehet YouTube videóra mutató URL, vagy saját platformról kiszolgált tartalom. <!-- Biztos hogy engedünk custom kiszolgálót? Also, ide be lehetne írni, hogy a library mit supportál még. -->

A videó médiatartalom típus elérhetővé tesz egy vezérlő gombot is: a szünet/lejátszát (pause/play) gombot.

# Fejlesztői dokumentáció

<!-- Projekt szolgáltatás szintű felépítése -->
<!-- main service, apriltag service, minio, redis -->

## Quick Start

<!-- Docker Compose beállítása dev env-be -->

<!-- HOSTS fájl létrehozása (legyen külön fejezet, hogy lehessen rá referálni a felhasználói doksiból) -->

## Adatbázis

<!-- Redis ismertetése, indoklás -->

<!-- séma -->

<!-- Szoba azonosító generálás -->

## Fájl tárolás

<!-- S3, Minio -->

<!-- presigned linkek -->

## Main service

<!-- react, t3 stack, full stack -->

<!-- pathek -->

<!-- serialization, pubsub -->

<!-- Fájlfeltöltés folyamata -->

<!-- médiatípusok ismertetése, új médiatípusok hozzáadásának folyamata -->

## Kalibrálás

### Kalibrálási szolgáltatás

<!-- Apriltag, OpenCV, Python, FastAPI -->

### Kalibrálási folyamat

<!-- End to end mátrixok -->

<!-- Hasznos kód részletek -->

## Tesztek

<!-- TODO: Tesztek -->

# Összegzés

# Irodalomjegyzék
