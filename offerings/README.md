# Semestrální zdroje

Tento adresář obsahuje ručně upravované zdroje pro jednotlivé běhy kurzu. Každý semestr má jeden konfigurační soubor YAML a vlastní adresář s obsahovými fragmenty Markdown.

## Co upravovat

- `YYYY-YY.yml` obsahuje označení a stav semestru, odkazy na obsahové fragmenty a stabilní vydání jednotlivých lekcí.
- `YYYY-YY/rozvrh.md` obsahuje rozvrh a témata výuky.
- `YYYY-YY/hodnoceni.md` obsahuje pravidla zakončení kurzu.
- `YYYY-YY/vyucujici.md` obsahuje tým daného semestru.
- Portréty použité ve `vyucujici.md` ukládejte jako optimalizované lokální soubory do `assets/instructors/`, doplňte smysluplný alternativní text a na stránce uveďte zdroj fotografie.

Soubory `.md` jsou záměrně pouze obsahové fragmenty bez Quarto front matter. Nejsou samostatnými webovými stránkami a mohou být vloženy do aktuální stránky i do archivního snímku stejného semestru.

## Co neupravovat

Adresáře `_generated/`, `semestry/` a `rok/` vznikají automaticky. Jejich `.md` a `.qmd` soubory neupravujte ručně, protože další sestavení je přepíše. Kořenové `.qmd` soubory jsou trvalé Quarto obálky stránek; upravují se pouze při změně názvu, metadat nebo rozvržení stránky.

Po změně semestrálních zdrojů spusťte:

```powershell
Rscript R/render_site.R
```

Sestavení načte YAML a Markdown fragmenty, vytvoří aktuální a archivní Quarto stránky a vyrenderuje web do `_site/`.
