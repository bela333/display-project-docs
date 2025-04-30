## Mainservice tesztelése

Mivel a Mainservice több különböző komponensre hagyatkozik, amelyeket nem lehet leválasztani róla, ezért itt manuális tesztelést alkalmazok.

![A Mainservice használati eset diagramja](images/usecases.svg){width=50%}

Tesztesetek listája:

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
| Sikeres kalibrálás, kalibrációs kép megváltoztatásával | Szoba megnyitva, kalibrálási állapotban, fel van töltve kalibrációs kép. Másik eszközön szoba megnyitva, megjelenítő módban | Lépjen be egy új eszközön a szobába, megjelenítő módban. Készítsen egy képet, ahol az új megjelenítő kliens kalibráló jele jól látszik. Kattintson az "Upload calibration image" gombra, majd töltse fel ezt a képet. | A kalibrálási kép megváltozik, rajta csak és kizárólag az új megjelenítő kliens kijelzője látszik. |
| Kalibrációs kép szinkronizálás | Egyes eszközön szoba megnyitva, kalibrálási állapotban, nincs feltöltve kalibrációs kép. Kettes eszközön szoba megnyitva, konfiguráló módban. Hármas eszközön szoba megnyitva, megjelenítő módban. | Készítsen egy képet, ahol az hármas kliens kalibráló jele jól látszik. Az egyes kliensen kattintson az "Upload calibration image" gombra, majd töltse fel az előbb készített képet. | A kép sikeresen feltöltődik, és megjelenik a kettes eszközön is. |
| Közvetítés, kalibrációs képpel | Szoba megnyitva, kalibrálási állapotban, kalibrációs kép fel van töltve | Kattintson a "Broadcast" gombra | Megjelenik a közvetítési oldal |
| Közvetítés állapotváltozás szinkronizálás | Szoba megnyitva, kalibrálási állapotban, kalibrációs kép fel van töltve. Másik eszközön szoba megnyitva, konfiguráló módban. | Kattintson a "Broadcast" gombra | Megjelenik a közvetítési oldal a másik eszközön is |
| Kalibrálás állapotváltozás | Szoba megnyitva, közvetítési állapotban | Kattintson a "Calibrate" gombra | Megjelenik a kalibrálási oldal |
| Kalibrálás állapotváltozás szinkronizálás | Szoba megnyitva, közvetítési állapotban. Másik eszközön szoba megnyitva, konfiguráló módban. | Kattintson a "Calibrate" gombra | Megjelenik a kalibrálási oldal a másik eszközön is |
| Fénykép feltöltése | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. Másik eszközön szoba megnyitva, szintén konfiguráló módban. "Photos" médiatartalom típus kiválasztva. | Kattintson az "Upload photo" gombra és töltsön fel egy képet, például az apriltagservice/\hspace{0pt}test/\hspace{0pt}image_no_tag.png fájlt. | A kép megjelenik a listában, a helyes indexképpel és a helyes fájlnévvel. A kép szintén megjelenik a másik eszközön. |
| Hibás kiterjesztésű fénykép feltöltés | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "Photos" médiatartalom típus kiválasztva. | Kattintson az "Upload photo" gombra és töltse fel a `README.md` fájlt. | A bal alsó sarokban megjelenik egy "Invalid extension" hiba, a lista nem változik meg. |
| Túl nagy fénykép feltöltés | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "Photos" médiatartalom típus kiválasztva. | Kattintson az "Upload photo" gombra és töltsön fel egy 16 MiB-nál nagyobb fájlt (lásd: -@sec:large-file. fejezet) | A bal alsó sarokban megjelenik egy "File too large." hiba, a lista nem változik meg. |
| Fénykép kiválasztása | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "Photos" médiatartalom típus kiválasztva, legalább egy kép feltöltve. Másik eszközön szoba megnyitva, megjelenítő módban. | Kattintson az egyik feltöltött képre. | A bal oldali előnézeten megjelenik a kiválasztott kép. A kép szintén megjelenik a megjelenítő kliensen. |
| iFrame hibásan formázott URL-el | Szoba megnyitva, közvetítési állapotban, konfiguráló módban "IFrame" médiatartalom típus kiválasztva. | Írja be az "Embed url" mezőbe a következő karakterláncot: "Lorem ipsum dolor sit amet". Kattintson a "Play" gombra. | Nem történik semmi. |
| iFrame helyes URL-el | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "IFrame" médiatartalom típus kiválasztva. Másik eszközön szoba megnyitva, megjelenítő módban. | Írja be az "Embed url" mezőbe egy beágyazható oldal URL-jét^[Például: https://www.youtube.com/embed/dQw4w9WgXcQ]. Kattintson a "Play" gombra. | A jobb oldali előnézeten megjelenik a beágyazás. A beágyazás szintén megjelenik a megjelenítő kliensen. |
| Videó hibásan formázott URL-el | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "Video" médiatartalom típus kiválasztva. | Írja be az "Embed url" mezőbe a következő karakterláncot: "Lorem ipsum dolor sit amet". Kattintson a "Play" gombra. | "Invalid url" hiba. A megjelenített tartalom nem változik. |
| Videó nem engedélyezett URL-el | Szoba megnyitva, közvetítési állapotban, konfiguráló módban. "Video" médiatartalom típus kiválasztva. | Írja be az "Embed url" mezőbe a következő karakterláncot: "http://google.com". Kattintson a "Play" gombra. | "Unsupported URL" hiba. A megjelenített tartalom nem változik. |
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
