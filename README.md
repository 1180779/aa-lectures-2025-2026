# Algorytmy Zaawansowane — notatki z wykładów

Notatki w LaTeX-u do przedmiotu **Algorytmy Zaawansowane** (Advanced Algorithms),
opracowane na podstawie wykładów Michała Tuczyńskiego na Wydziale Matematyki
i Nauk Informacyjnych Politechniki Warszawskiej (semestr letni 2025/2026).

## Struktura repozytorium

| Ścieżka          | Opis                                                                         |
|------------------|------------------------------------------------------------------------------|
| `notes/`         | Pełne notatki &mdash; wszystkie wykłady w całości (jedyne źródło).                 |
| `examples/`      | Zestaw przykładowych instancji do powtórki (`przyklady.tex`) wraz z rozwiązaniami w `examples/rozwiazania/`. |
| `preamble.tex`   | Wspólna preambuła (`\documentclass`, pakiety, środowiska) dołączana przez `notes/main.tex` i `examples/przyklady.tex`. |

Katalog `notes/` zawiera `main.tex`, który dołącza wspólną preambułę przez
`\input{../preamble}` oraz poszczególne pliki wykładów `lectXX-DD-MM-2026.tex`.

## Wersje

Z notatek powstają **trzy** wersje PDF, sterowane zmiennymi środowiskowymi
`AZ_HIGHLIGHT` i `AZ_SKIP` (czytanymi przez preambułę):

| Wersja | `AZ_HIGHLIGHT` | `AZ_SKIP` | Opis |
|--------|----------------|-----------|------|
| `AZ_lectures` | (brak / `0`) | `0` | Zwykłe notatki. |
| `AZ_lectures_highlighted` | `1` | `0` | Materiał obowiązkowy (twierdzenia wraz z dowodami) na wyróżniającym tle &mdash; dla lepszej czytelności tego, co najważniejsze na egzaminie. |
| `AZ_lectures_exam` | `1` | `1` | Jak wyżej, ale z wyciętymi dowodami nieobowiązkowymi &mdash; szybka powtórka przed egzaminem. |

Dodatkowo z `examples/przyklady.tex` powstaje `AZ_examples` &mdash; zestaw
przykładowych instancji do samodzielnego prześledzenia wraz z rozwiązaniami.

## Kompilacja

Dokumenty kompiluje się przy użyciu **LuaLaTeX** (nie pdfLaTeX — używane są
fonty OpenType / `fontspec`). Z katalogu `notes/`:

```sh
latexmk main.tex                    # wersja zwykła
AZ_HIGHLIGHT=1 latexmk -g main.tex  # wersja z wyróżnieniami
```

(konfiguracja silnika znajduje się w `.latexmkrc`). Najwygodniej zbudować
wszystkie wersje (notatki + przykłady) naraz skryptem `./build.sh` w katalogu
głównym. Można też ograniczyć budowanie do jednej części:

```sh
./build.sh --notes      # tylko notatki
./build.sh --examples   # tylko przykłady
```

Pliki pomocnicze ostatniej kompilacji są zostawiane (czyszczone dopiero na
początku kolejnego uruchomienia).

## Wydania

Tagowane wydania publikują skompilowane pliki PDF. Workflow
`.github/workflows/discord-release.yml` automatycznie pobiera archiwum źródłowe
wydania, wyciąga z niego pliki PDF i wysyła je na kanał Discord.
