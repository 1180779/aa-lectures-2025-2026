# Algorytmy Zaawansowane — notatki z wykładów

Notatki w LaTeX-u do przedmiotu **Algorytmy Zaawansowane** (Advanced Algorithms),
opracowane na podstawie wykładów Michała Tuczyńskiego na Wydziale Matematyki
i Nauk Informacyjnych Politechniki Warszawskiej (semestr letni 2025/2026).

## Struktura repozytorium

| Ścieżka          | Opis                                                                         |
|------------------|------------------------------------------------------------------------------|
| `notes/`         | Pełne notatki &mdash; wszystkie wykłady w całości (jedyne źródło).                 |
| `preamble.tex`   | Wspólna preambuła (`\documentclass`, pakiety, środowiska) dołączana przez `notes/main.tex`. |

Katalog `notes/` zawiera `main.tex`, który dołącza wspólną preambułę przez
`\input{../preamble}` oraz poszczególne pliki wykładów `lectXX-DD-MM-2026.tex`.

## Wersje

Z jednego źródła powstają **dwie** wersje PDF, sterowane zmienną środowiskową
`AZ_HIGHLIGHT` (czytaną przez preambułę):

| Wersja | `AZ_HIGHLIGHT` | Opis |
|--------|----------------|------|
| `AZ_lectures` | (brak / `0`) | Zwykłe notatki. |
| `AZ_lectures_highlighted` | `1` | Materiał obowiązkowy (twierdzenia wraz z dowodami) na wyróżniającym tle &mdash; dla lepszej czytelności tego, co najważniejsze na egzaminie. |

## Kompilacja

Dokumenty kompiluje się przy użyciu **LuaLaTeX** (nie pdfLaTeX — używane są
fonty OpenType / `fontspec`). Z katalogu `notes/`:

```sh
latexmk main.tex                    # wersja zwykła
AZ_HIGHLIGHT=1 latexmk -g main.tex  # wersja z wyróżnieniami
```

(konfiguracja silnika znajduje się w `.latexmkrc`). Najwygodniej zbudować obie
wersje naraz skryptem `./build.sh` w katalogu głównym.

## Wydania

Tagowane wydania publikują skompilowane pliki PDF. Workflow
`.github/workflows/discord-release.yml` automatycznie pobiera archiwum źródłowe
wydania, wyciąga z niego pliki PDF i wysyła je na kanał Discord.
