# Biostatistika MB120P163 – studentský web

Tento repozitář obsahuje veřejný Quarto hub kurzu Biostatistika. Web zobrazuje aktuální akademický rok, neměnné roční archivy a odkazy na schválené release materiály z repozitářů `L01`–`L12`.

## Lokální náhled

Lokální render používá poslední uložený soubor `data/catalog.json`. Pokud dosud neproběhla synchronizace, všechny lekce se bezpečně zobrazí jako `Připravujeme`.

Před každým podporovaným renderem se vzhled synchronizuje s kanonickým
repozitářem `_brand`. V pracovním prostoru se použije lokální sourozenec
`../_brand`; v CI se stáhnou generované soubory z GitHubu. Commitnutá kopie v
`assets/brand/` umožňuje render bez připojení a při synchronizaci se kontrolují
otisky souborů i základní barvy a fonty značky. Soubor `assets/styles.scss`
obsahuje pouze rozvržení specifické pro webový rozcestník.

```r
source("R/render_site.R")
```

Aktuální veřejné manifesty lze před renderem načíst příkazem:

```r
source("R/sync_catalog.R")
```

## Zdroj materiálů

Každá týdenní lekce publikuje explicitně povolený balíček podle svého `website-release.yml`. Hub nic nerenderuje z cizích QMD a nespouští analytický kód lekcí. Pouze načte veřejný `manifest.json`, ověří jej a vytvoří odkazy na neměnnou cestu `/LWW/releases/<tag>/`.

## Akademické roky

Soubor `config/course.yml` určuje aktuální rok a seznam lekcí. Každý ročník má vlastní soubor v `offerings/`:

- `frozen: false` a `release: null` znamená, že aktivní ročník používá nejnovější schválený release dané lekce;
- konkrétní tag připne přesnou verzi;
- `frozen: true` zakáže nepřipnuté lekce a používá se pro uzavřený ročník.

Na konci roku nejprve spusťte synchronizaci katalogu a poté:

```r
source("R/freeze_offering.R")
```

Výsledný diff manifestu ročníku musí projít lidskou kontrolou. Pro nový akademický rok zkopírujte zmrazený manifest, změňte rok, nastavte `frozen: false`, ponechte zděděné tagy a přidejte rok do `config/course.yml`. Nový release postupně nahradí zděděné verze; web je do té doby označí jako převzaté.

## Automatické publikování

Workflow reaguje na push do `main`, ruční spuštění a událost `lesson-released`. Událost z týdenního repozitáře pouze spustí synchronizaci; hub znovu ověří veřejný manifest a deklarovaný tag. GitHub App pro okamžité události musí být instalována pouze pro tento repozitář a její secrets musí být zpřístupněny release workflow týdenních repozitářů.

V nastavení repozitáře musí být GitHub Pages nakonfigurovány na zdroj **GitHub Actions**.
