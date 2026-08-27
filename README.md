# Biostatistika a plánování ekologických pokusů (MB120P163) – studentský HUB

Tento repozitář obsahuje veřejný Quarto web kurzu **Biostatistika a plánování ekologických pokusů** na Přírodovědecké fakultě Univerzity Karlovy. HUB je hlavním veřejným průvodcem kurzem: obsahuje informace o aktuálním semestru, stabilní studijní materiály, rozvrh, pravidla hodnocení, tým kurzu a archiv neměnných semestrálních snapshotů.

Veřejný web: [cuni-natur-biostatistics.github.io](https://cuni-natur-biostatistics.github.io/)

SIS zůstává místem zápisu a oficiální evidence. [Moodle](https://dl2.cuni.cz/course/view.php?id=106) slouží pro testy, zadání, odevzdávání, výsledky a neveřejná oznámení.

## Struktura zdrojů

| Cesta | Úloha |
| --- | --- |
| `config/course.yml` | Základní metadata kurzu, aktuální semestr a seznam lekcí L01–L12. |
| `offerings/YYYY-YY.yml` | Stav semestru, odkazy na obsahové fragmenty a případně připnuté release tagy. |
| `offerings/YYYY-YY/` | Ručně upravovaný rozvrh, hodnocení a tým daného semestru. |
| `assets/instructors/` | Lokální optimalizované portréty vyučujících. |
| `assets/styles.scss` | Rozvržení a komponenty specifické pro HUB; kanonický vzhled zůstává v repozitáři `_brand`. |
| `R/` | Synchronizace katalogu a značky, generování stránek, zmrazení semestru a render webu. |
| `_generated/`, `semestry/`, `rok/` | Odvozené zdroje vytvářené sestavením; neupravují se ručně. |
| `_site/` | Lokální render webu; není verzován. |

Podrobnosti k semestrálním fragmentům jsou v [`offerings/README.md`](offerings/README.md).

## Lokální sestavení

Je potřeba mít nainstalované R, Quarto a závislosti zaznamenané v `renv.lock`. Po prvním klonování lze R prostředí obnovit příkazem:

```powershell
Rscript -e "renv::restore()"
```

Podporovaný kompletní render synchronizuje kanonickou značku, vytvoří odvozené zdroje a vyrenderuje web do `_site/`:

```powershell
Rscript R/render_site.R
```

Render používá poslední uložený `data/catalog.json`. Pokud katalog dosud neobsahuje vydání lekce, zobrazí se její karta bezpečně jako připravovaná. Chcete-li před renderem načíst aktuální veřejné manifesty stabilních vydání, spusťte:

```powershell
Rscript R/sync_catalog.R
Rscript R/render_site.R
```

Samotné `quarto render` je vhodné jen pro úzkou kontrolu již vygenerované stránky; neobnoví katalog, kanonickou značku ani semestrální zdroje.

## Materiály lekcí a veřejné adresy

Každá lekce publikuje pouze soubory povolené v `website-release.yml`. HUB nerenderuje QMD z týdenních repozitářů a nespouští jejich analytický kód; načítá veřejný `manifest.json`, ověřuje jej a vytváří odkazy.

Každý lekční web má tři kanály:

- `/LXX/preview/` obsahuje nejnovější commitnuté HTML z větve `main` a slouží pro kontrolu vyučujícím;
- `/LXX/current/` ukazuje na poslední stabilní tag;
- `/LXX/releases/<tag>/` uchovává neměnnou historickou verzi.

HUB na vývojový kanál `preview` neodkazuje. Karty aktuálního semestru používají stabilní `/LXX/current/`, zatímco odkaz na repozitář vede na `main`. Archivní karty používají `/LXX/releases/<tag>/` a stejný tag v repozitáři. Odkaz na repozitář je veřejně funkční pouze tehdy, když je příslušný týdenní repozitář veřejný; tuto podmínku je nutné ověřit před prvním vydáním lekce.

## Veřejnost, soukromí a licence

HUB a Pages jednotlivých lekcí jsou veřejné publikační plochy. Do `website-release.yml` proto patří jen schválené výukové materiály, veřejná cvičení a data s ověřenou provenancí a podmínkami užití. Osobní údaje studentů, individuální výsledky, neveřejná zadání a řešení, přístupové údaje a interní provozní poznámky patří do Moodle nebo jiného schváleného soukromého systému.

Manifest je allowlist release balíčku, nikoli ochrana veřejného repozitáře: pokud je týdenní repozitář veřejný, je veřejný celý jeho commitnutý obsah a historie. Před změnou viditelnosti je proto potřeba provést samostatný audit celého repozitáře.

Původní výukový obsah kurzu je otevřeně licencován pod CC BY 4.0 a software pod licencí MIT. Přesné vymezení, doporučenou citaci a výjimky shrnuje [`LICENSE.md`](LICENSE.md). Převzatá data, obrázky, fonty, loga a další položky zůstávají pod vlastními podmínkami a atribucemi.

## Semestry a archiv

Soubor `config/course.yml` určuje aktuální semestr a seznam semestrů. Každý semestr má konfigurační soubor v `offerings/`, který vedle tagů lekcí odkazuje na verzovaný rozvrh, hodnocení a tým.

- `frozen: false` a nepřipnutý tag znamenají, že aktivní semestr používá nejnovější schválené vydání dané lekce;
- konkrétní tag připne přesnou verzi;
- `frozen: true` připne všechna vydání a uloží kontrolní součty rozvrhu, hodnocení a týmu pro uzavřený snapshot.

Na konci semestru nejprve synchronizujte katalog a poté spusťte zmrazení:

```powershell
Rscript R/sync_catalog.R
Rscript R/freeze_offering.R
```

Výsledný diff konfigurace musí projít lidskou kontrolou. Generátor později odmítne změněný rozvrh, hodnocení nebo tým uzavřeného semestru. Pro nový semestr zkopírujte konfiguraci a obsahový adresář, nastavte nový identifikátor a popisek, ponechte `frozen: false`, odstraňte staré kontrolní součty a přidejte semestr do `config/course.yml`.

Kanonické snapshoty jsou na `/semestry/<id>/`. Staré adresy `/rok/<id>/` a `/rok/<id>/<lekce>/` zůstávají pouze jako kompatibilní přesměrování.

## Tým a portréty

Složení týmu je součástí semestrálního snapshotu v `offerings/YYYY-YY/vyucujici.md`. Portréty se ukládají lokálně do `assets/instructors/`, optimalizují pro web a mají popisný alternativní text. Zdroj fotografie musí být uveden v kreditní poznámce na stránce vyučujících; fotografie se nepřebírá jen na základě toho, že je veřejně dostupná.

## Automatické publikování

Workflow `publish.yml` reaguje na push do `main`, ruční spuštění a událost `lesson-released`. Vždy znovu synchronizuje veřejné manifesty, vyrenderuje celý HUB a nasadí `_site/` přes GitHub Pages.

Týdenní repozitáře volají dva znovupoužitelné workflow uložené v tomto repozitáři:

- `preview.yml` sestaví `/preview/` po změně commitnutých HTML na `main` a zachová existující stabilní kanály;
- `release.yml` vytvoří release balíček, obnoví `/current/`, zachová `/preview/` a volitelně odešle událost `lesson-released` do HUBu.

Pro okamžitou aktualizaci HUBu používá release workflow secrets `HUB_APP_ID` a `HUB_APP_PRIVATE_KEY`. Bez nich se release a lekční Pages nasadí, ale HUB je potřeba obnovit ručním spuštěním `Publish course hub` nebo dalším pushem do jeho `main`.

V HUB repozitáři i v každém lekčním repozitáři musí být GitHub Pages jednorázově nastaveny na zdroj **GitHub Actions**. Lekční repozitáře navíc potřebují prostředí `github-pages`, které dovoluje větev `main` a odpovídající tagy `LXX-v*`.

## Validace

Základní lokální kontroly lze spustit z kořene repozitáře:

```powershell
Rscript tests/source_validation_test.R
Rscript tests/hub_semester_model_test.R
```

Kontrola živého manifestu L01 vyžaduje připojení k internetu:

```powershell
Rscript tests/live_catalog_contract_test.R
```

Test sestavení lekčních Pages vyžaduje Ruby a nástroj `zip`:

```powershell
ruby tests/release_automation/assemble_lesson_pages_test.rb
```
