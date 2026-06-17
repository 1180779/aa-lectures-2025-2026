# Algorytmy Zaawansowane — notatki z wykładów

Notatki w LaTeX-u do przedmiotu **Algorytmy Zaawansowane** (Advanced Algorithms),
opracowane na podstawie wykładów Michała Tuczyńskiego na Wydziale Matematyki
i Nauk Informacyjnych Politechniki Warszawskiej (semestr letni 2025/2026).

## Struktura repozytorium

| Ścieżka          | Opis                                                                         |
|------------------|------------------------------------------------------------------------------|
| `notes/`         | Pełne notatki &mdash; wszystkie wykłady w całości.                                 |
| `exam/`          | Wersja egzaminacyjna &mdash; okrojona do materiału obowiązującego na egzaminie.    |
| `preamble.tex`   | Wspólna preambuła (`\documentclass`, pakiety, środowiska) dzielona przez obie wersje. |

Każdy katalog zawiera `main.tex`, który dołącza wspólną preambułę przez
`\input{../preamble}` oraz poszczególne pliki wykładów `lectXX-DD-MM-2026.tex`.

## Kompilacja

Dokumenty kompiluje się przy użyciu **LuaLaTeX** (nie pdfLaTeX — używane są
fonty OpenType / `fontspec`). Z katalogu `notes/` lub `exam/`:

```sh
latexmk main.tex
```

(konfiguracja silnika znajduje się w `.latexmkrc`).

## Wydania

Tagowane wydania publikują skompilowane pliki PDF. Workflow
`.github/workflows/discord-release.yml` automatycznie pobiera archiwum źródłowe
wydania, wyciąga z niego pliki PDF i wysyła je na kanał Discord.
