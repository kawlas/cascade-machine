CASCADE MACHINE — Przewodnik dla Początkujących
Co to jest CASCADE MACHINE?
Wyobraź sobie, że masz kilku programistów-asystentów którzy siedzą w Twoim komputerze i czekają na Twoje polecenia. Mówisz im po polsku (lub angielsku) co chcesz zrobić, a oni piszą kod za Ciebie.

Problem: Każdy asystent jest inny — jeden jest szybki ale prosty, drugi jest mądry ale wolny, trzeci jest w chmurze i ma limit użyć dziennie.

Rozwiązanie: CASCADE MACHINE to system, który:

text

1. Automatycznie wybiera najlepszego asystenta do Twojego zadania
2. Jeśli jeden nie da rady — sam próbuje z lepszym
3. Jeśli popełni błąd — sam cofa zmiany i próbuje ponownie
4. Robi to wszystko ZA DARMO (bez płacenia za AI)
5. Działa nawet BEZ INTERNETU (AI na Twoim komputerze)
Analogia z życia
Pomyśl o tym jak o warsztacie samochodowym:

text

🔧 Prosty problem (wymiana żarówki):
   → Młodszy mechanik sobie poradzi (szybko, tanio)
   
🔧 Średni problem (wymiana hamulców):
   → Doświadczony mechanik (trwa dłużej, ale zrobi dobrze)
   
🔧 Trudny problem (remont silnika):
   → Specjalista (najwolniejszy, ale jedyny kto da radę)

CASCADE robi to samo, ale z programowaniem:
   → Prosty kod: lokalny AI (natychmiast, za darmo)
   → Trudniejszy kod: AI w chmurze (kilka sekund, za darmo)
   → Bardzo trudny: najlepszy AI (wolniej, nadal za darmo)
Co potrzebujesz zanim zaczniesz
Wymagania sprzętowe
text

Komputer:
├── macOS (MacBook, iMac, Mac Mini) — NAJLEPIEJ
│   └── M1/M2/M3/M4 chip — AI działa na nim świetnie
├── Linux — też działa
└── Windows — działa przez WSL2 (Windows Subsystem for Linux)

Dysk: minimum 25 GB wolnego miejsca (AI modele zajmują sporo)
RAM: minimum 8 GB (lepiej 16 GB+)
Internet: potrzebny do instalacji, potem OPCJONALNY
Wymagane programy (zainstalujemy je krok po kroku)
text

1. Terminal     — już masz (wbudowany w system)
2. VS Code      — edytor kodu (darmowy)
3. Homebrew      — menedżer programów dla Mac (darmowy)
4. Git          — system wersjonowania kodu (darmowy)
5. Python 3     — język programowania (darmowy)
6. Ollama       — AI na Twoim komputerze (darmowy)
7. Aider        — asystent programistyczny (darmowy)
Nie martw się jeśli nie wiesz co to jest — zainstalujemy to wszystko razem.

INSTALACJA — Krok po kroku
Krok 1: Otwórz Terminal
text

Na Macu:
1. Naciśnij Command + Spacja (otworzy się Spotlight)
2. Wpisz: Terminal
3. Naciśnij Enter
4. Pojawi się czarne (lub białe) okno z migającym kursorem
   — to jest Terminal. Tu będziemy wpisywać komendy.

WAŻNE: Każdą komendę wpisujesz i naciskasz ENTER żeby ją wykonać.
Komendy kopiuj DOKŁADNIE tak jak są napisane.
Krok 2: Zainstaluj Homebrew (menedżer programów)
Wklej tę komendę w Terminal i naciśnij Enter:

Bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
text

Co się dzieje:
- Terminal poprosi Cię o hasło do komputera
- Wpisz je (NIE ZOBACZYSZ gwiazdek — to normalne)
- Naciśnij Enter
- Poczekaj 2-5 minut aż się zainstaluje
- Gdy zobaczysz "Installation successful" — gotowe!

Jeśli Terminal pokaże instrukcje typu "Add Homebrew to your PATH":
Skopiuj i wklej te komendy które pokazał (zazwyczaj 2 linie).
Sprawdź czy działa:

Bash

brew --version
Powinno pokazać coś jak: Homebrew 4.x.x

Krok 3: Zainstaluj podstawowe narzędzia
Bash

brew install git python3
Poczekaj aż się zainstaluje (1-3 minuty).

Krok 4: Zainstaluj VS Code (jeśli nie masz)
Bash

brew install --cask visual-studio-code
Albo pobierz ze strony: https://code.visualstudio.com

Krok 5: Zainstaluj Ollama (AI na Twoim komputerze)
To jest najważniejszy program — pozwala uruchomić sztuczną inteligencję LOKALNIE na Twoim komputerze, bez internetu, bez opłat.

Bash

brew install ollama
Uruchom Ollama (musi działać w tle):

Bash

brew services start ollama
Poczekaj 10 sekund, potem sprawdź:

Bash

ollama --version
Powinno pokazać wersję.

Krok 6: Pobierz modele AI
Teraz pobierzemy "mózgi" AI na Twój komputer. To jednorazowe — potem działają offline.

Bash

# Mały, szybki model (2 GB) — do prostych zadań
ollama pull devstral-small

# Główny model do kodowania (20 GB) — najlepszy
# UWAGA: To potrwa 5-15 minut w zależności od internetu
ollama pull qwen3-coder

# Model do myślenia i wyjaśniania (8 GB)
ollama pull deepseek-r1:14b
text

WSKAZÓWKA: Jeśli masz mało miejsca na dysku:
- Pobierz TYLKO devstral-small (2 GB) — wystarczy na start
- Resztę pobierzesz później gdy będziesz potrzebować

Jak sprawdzić ile masz miejsca:
  df -h ~
  (patrz na kolumnę "Avail")
Sprawdź czy modele się pobrały:

Bash

ollama list
Powinno pokazać listę pobranych modeli.

Krok 7: Zainstaluj Aider (asystent programistyczny)
Bash

pip3 install aider-chat
Sprawdź:

Bash

aider --version
Krok 8: SZYBKI TEST — Sprawdź czy AI działa
Bash

# Utwórz tymczasowy folder testowy
mkdir ~/test-ai
cd ~/test-ai
git init

# Uruchom Aider z lokalnym AI
aider --model ollama_chat/devstral-small

# Pojawi się prompt Aider. Wpisz:
# "create a file hello.py that prints Hello World"
# Naciśnij Enter
# AI powinien stworzyć plik hello.py!
# Wpisz /exit żeby wyjść
text

Jeśli to zadziałało — GRATULACJE! 🎉
AI działa na Twoim komputerze!

Jeśli nie zadziałało:
- Sprawdź czy Ollama jest uruchomiona: ollama list
- Jeśli nie: brew services start ollama
- Poczekaj 10 sekund i spróbuj ponownie
Krok 9: Zainstaluj CASCADE MACHINE
Teraz zainstalujemy sam system CASCADE — to skrypty które automatyzują wszystko.

Bash

# Utwórz folder CASCADE
mkdir -p ~/.cascade/logs ~/.cascade/experiments

# Utwórz puste pliki do logowania
touch ~/.cascade/usage.jsonl
touch ~/.cascade/learnings.jsonl
Teraz musisz stworzyć pliki CASCADE. Masz dwie opcje:

Opcja A: Automatycznie (jeśli masz playbook.txt)
Bash

# Jeśli masz plik playbook.txt z całym kodem:
cd folder-gdzie-masz-playbook
aider --model ollama_chat/qwen3-coder \
  --message "Read playbook.txt and create all CASCADE files 
  in ~/.cascade/ directory. Make them executable. 
  Add aliases to ~/.zshrc." --yes
Opcja B: Ręcznie (bezpieczniejsza)
Otwórz VS Code i utwórz pliki ręcznie:

Bash

# Otwórz VS Code w folderze CASCADE
code ~/.cascade/
Potem skopiuj zawartość plików router.sh, heal.sh, init-project.sh, nightly.sh z playbooka do odpowiednich plików.

Po stworzeniu plików — uczyń je wykonywalnymi:

Bash

chmod +x ~/.cascade/router.sh
chmod +x ~/.cascade/heal.sh
chmod +x ~/.cascade/init-project.sh
chmod +x ~/.cascade/nightly.sh
Krok 10: Dodaj skróty komend
Otwórz plik konfiguracyjny shella:

Bash

# Na Macu (zsh):
nano ~/.zshrc

# Na Linux (bash):
# nano ~/.bashrc
text

MINI-TUTORIAL: Jak używać nano (edytor tekstu w terminalu):
- Strzałki ↑↓←→ do poruszania się
- Wpisuj tekst normalnie
- Control+O potem Enter = ZAPISZ
- Control+X = WYJDŹ
Dodaj na końcu pliku ten blok:

Bash

# ═══ CASCADE MACHINE ═══
# Załaduj API keys
[ -f "$HOME/.cascade/.env" ] && source "$HOME/.cascade/.env"

# Lokalne AI (darmowe, bez limitu)
alias fast='aider --model ollama_chat/qwen3-coder --auto-commits --yes'
alias think='aider --model ollama_chat/deepseek-r1:14b --auto-commits --yes'
alias quick='aider --model ollama_chat/devstral-small --auto-commits --yes'

# Cloud AI (darmowe, z dziennym limitem)
alias cloud='aider --model groq/llama-3.3-70b-versatile --auto-commits --yes'
alias smart='aider --model openrouter/mistralai/devstral-2 --auto-commits --yes'

# Narzędzia CASCADE
alias heal='~/.cascade/heal.sh'
alias tokens='~/.cascade/router.sh status'
alias cascade-init='~/.cascade/init-project.sh'
Zapisz (Ctrl+O, Enter) i wyjdź (Ctrl+X).

Załaduj zmiany:

Bash

source ~/.zshrc
Krok 11: Skonfiguruj darmowe klucze API (OPCJONALNE)
To daje Ci dostęp do AI w chmurze — przydatne gdy lokalne AI nie wystarczy. Ale CASCADE działa BEZ TEGO (z samym Ollama).

Bash

# Utwórz plik na klucze
cp ~/.cascade/.env.cascade ~/.cascade/.env
nano ~/.cascade/.env
Jak zdobyć darmowe klucze (każdy zajmie 2 minuty):

text

1. OpenRouter (29 darmowych modeli AI):
   → Wejdź na: https://openrouter.ai
   → Kliknij "Sign Up" (zarejestruj się)
   → Idź do "Keys" → "Create Key"
   → Skopiuj klucz i wklej do .env przy OPENROUTER_API_KEY=

2. Groq (najszybsze darmowe AI):
   → Wejdź na: https://console.groq.com
   → Zarejestruj się
   → "API Keys" → "Create API Key"
   → Skopiuj i wklej przy GROQ_API_KEY=

3. Google AI Studio (Gemini za darmo):
   → Wejdź na: https://aistudio.google.com
   → Zaloguj się kontem Google
   → "Get API Key" → "Create API Key"
   → Skopiuj i wklej przy GOOGLE_AI_KEY=

Nie musisz mieć WSZYSTKICH kluczy.
Nawet jeden wystarczy jako backup dla Ollama.
Możesz dodawać kolejne później.
Krok 12: Sprawdź czy wszystko działa
Bash

# Załaduj nowe ustawienia
source ~/.zshrc

# Sprawdź status
tokens
Powinieneś zobaczyć tabelkę z informacjami o dostępnych modelach i limitach.

JAK UŻYWAĆ CASCADE — Codzienna praca
Scenariusz 1: Zaczynasz nowy projekt
text

KROK 1: Otwórz VS Code

KROK 2: Otwórz Terminal w VS Code
         → Kliknij "Terminal" w menu górnym
         → Kliknij "New Terminal"
         → Na dole pojawi się Terminal

KROK 3: Utwórz nowy projekt
Bash

# W terminalu VS Code:
mkdir ~/moj-pierwszy-projekt
cd ~/moj-pierwszy-projekt
cascade-init
text

Co się stało:
CASCADE automatycznie utworzył:
  ✅ AGENTS.md — instrukcje dla AI jak pisać kod w tym projekcie
  ✅ .aider.conf.yml — konfiguracja asystenta
  ✅ .cascade/ — folder z ustawieniami
  ✅ git repo — system wersji (na wypadek gdyby AI coś popsuł)
Bash

# KROK 4: Zacznij kodować z AI!
fast
text

Pojawi się prompt Aider. Teraz możesz rozmawiać z AI!
Wpisuj po polsku lub angielsku co chcesz zrobić.
Scenariusz 2: Codzienne kodowanie z AI
Po uruchomieniu fast widzisz:

text

Aider v0.xx.x
Model: ollama_chat/qwen3-coder
──────────────────────────────
> _
Teraz po prostu mów AI co ma zrobić:

text

PRZYKŁADY — co możesz wpisać:

PROSTE ZADANIA (AI zrobi w <5 sekund):
> stwórz plik index.html z prostą stroną powitalną
> dodaj przycisk "Kontakt" do strony
> zmień kolor tła na niebieski
> popraw literówkę w pliku about.html
> dodaj komentarze do kodu w app.js

ŚREDNIE ZADANIA (AI zrobi w 10-30 sekund):
> stwórz formularz kontaktowy z walidacją email
> dodaj dark mode do strony
> stwórz REST API w Python z trzema endpointami
> napisz testy do funkcji calculate_total
> zrefaktoryzuj plik utils.js — jest za długi

TRUDNE ZADANIA (użyj 'heal' zamiast 'fast'):
> zaimplementuj system logowania z JWT tokenami
> zrefaktoryzuj całą aplikację na wzorzec MVC
> stwórz system płatności z integracją Stripe
Scenariusz 3: AI popełnia błąd
text

To normalne! AI nie jest doskonałe. Oto co robisz:

OPCJA A: Popraw ręcznie
> popraw błąd w pliku X — powinno być Y zamiast Z

OPCJA B: Cofnij ostatnią zmianę
> /undo
(AI cofa swoją ostatnią edycję)

OPCJA C: Użyj heal (automatyczne naprawianie)
Wyjdź z Aider (/exit) i uruchom:
Bash

heal "opis co chcesz zrobić"
text

heal automatycznie:
1. Próbuje z lokalnym AI
2. Jeśli nie działa → próbuje z lepszym AI
3. Jeśli AI popełni błąd → cofa zmiany i próbuje ponownie
4. Powtarza aż się uda lub wyczerpie opcje
Scenariusz 4: Szybkie pytanie (bez kodowania)
Bash

# Chcesz coś zrozumieć? Użyj 'think':
think

# Potem wpisz pytanie:
> wyjaśnij mi co to jest REST API, prostym językiem
> jak działa pętla for w JavaScript?
> jakie są różnice między React a Vue?
Scenariusz 5: Sprawdzanie limitów
Bash

tokens
text

Zobaczysz coś takiego:

╔═══════════════════════════════════════════════════════╗
║  CASCADE — Token Usage (2026-03-23)                   ║
╠═══════════════════════════════════════════════════════╣
║  Ollama:      ✅ UNLIMITED  [qwen3-coder, devstral]   ║
║───────────────────────────────────────────────────────║
║  Groq:        ✅ ░░░░░░░░░░░░░░░░░░░░ 0/800 (0%)     ║
║  Google:      ✅ ░░░░░░░░░░░░░░░░░░░░ 0/1500 (0%)    ║
║  OpenRouter:  ✅ ░░░░░░░░░░░░░░░░░░░░ 0/150 (0%)     ║
╚═══════════════════════════════════════════════════════╝

Co to znaczy:
- Ollama: BEZ LIMITU — używaj ile chcesz!
- Groq: 800 zapytań dziennie — reset o północy
- Itd.

Wskazówka: Używaj 'fast' (Ollama) ile chcesz.
Cloud modele to backup na trudne zadania.
KOMENDY — Ściągawka
text

╔═══════════════════════════════════════════════════════════╗
║  KOMENDA          CO ROBI                    KOSZT       ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  ──── KODOWANIE ────                                     ║
║  fast              Główny asystent AI         $0 ∞       ║
║  think             AI do myślenia/wyjaśnień   $0 ∞       ║
║  quick             Najszybszy AI (prosty)     $0 ∞       ║
║                                                           ║
║  ──── CLOUD (trudne zadania) ────                        ║
║  cloud             AI w chmurze (Groq)        $0 800/d   ║
║  smart             AI w chmurze (Devstral)    $0 150/d   ║
║                                                           ║
║  ──── AUTOMATYCZNE ────                                  ║
║  heal "opis"       Samonaprawiające się AI    $0         ║
║                    (próbuje → fail → retry                ║
║                     → lepszy model → retry)              ║
║                                                           ║
║  ──── NARZĘDZIA ────                                     ║
║  tokens            Sprawdź limity dzienne     —          ║
║  cascade-init      Przygotuj nowy projekt     —          ║
║                                                           ║
║  ──── W AIDER (po uruchomieniu fast/think/cloud) ────    ║
║  /help             Pokaż pomoc                —          ║
║  /undo             Cofnij ostatnią zmianę     —          ║
║  /exit             Wyjdź z Aider              —          ║
║  /add plik.js      Dodaj plik do kontekstu    —          ║
║  /drop plik.js     Usuń plik z kontekstu      —          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
TYPOWY DZIEŃ PRACY — Krok po kroku
text

╔═══════════════════════════════════════════════════════════╗
║                    RANO                                    ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  1. Otwierasz MacBooka                                   ║
║     (Ollama uruchamia się automatycznie w tle)            ║
║                                                           ║
║  2. Otwierasz VS Code                                    ║
║     → File → Open Folder → wybierasz swój projekt        ║
║                                                           ║
║  3. Otwierasz Terminal w VS Code                         ║
║     → Terminal → New Terminal (lub Ctrl+`)               ║
║                                                           ║
║  4. Wpisujesz: fast                                      ║
║     → AI jest gotowy do pracy!                           ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║                    PRACA                                   ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  5. Mówisz AI co zrobić:                                 ║
║     > stwórz stronę logowania z formularzem               ║
║                                                           ║
║     AI:                                                   ║
║     - Czyta Twój projekt (AGENTS.md + istniejący kod)    ║
║     - Pisze kod                                           ║
║     - Automatycznie zapisuje zmiany                       ║
║     - Automatycznie commituje do git                      ║
║     (jeśli coś pójdzie nie tak → /undo)                  ║
║                                                           ║
║  6. Kontynuujesz:                                        ║
║     > dodaj walidację — email musi mieć @                 ║
║     > dodaj przycisk "Zapomnialem hasła"                  ║
║     > napisz test sprawdzający logowanie                  ║
║                                                           ║
║  7. Trudne zadanie? Wyjdź z Aider i użyj heal:          ║
║     /exit                                                 ║
║     heal "zrefaktoryzuj cały moduł logowania na OAuth2"   ║
║     (heal sam wybierze najlepszy model i poprawi błędy)  ║
║                                                           ║
╠═══════════════════════════════════════════════════════════╣
║                    WIECZÓR                                 ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  8. Kończysz pracę — zamykasz VS Code                    ║
║                                                           ║
║  9. O 23:00 automatycznie uruchamia się analiza:         ║
║     - Ile zadań udało się zrobić                         ║
║     - Które modele najlepiej działały                     ║
║     - Sugestie co poprawić                               ║
║     (Raport w ~/.cascade/logs/)                           ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
NAJCZĘSTSZE PROBLEMY I ROZWIĄZANIA
Problem: AI nie odpowiada
text

Objaw:  Wpisujesz komendę ale nic się nie dzieje
        lub pojawia się błąd "connection refused"

Przyczyna: Ollama nie jest uruchomiona

Rozwiązanie:
  1. Otwórz nowy Terminal
  2. Wpisz: ollama serve
  3. Poczekaj 5 sekund
  4. Wróć do poprzedniego Terminala i spróbuj ponownie

Sprawdzenie:
  ollama list
  (powinno pokazać listę modeli)
Problem: "Model not found"
text

Objaw:  Błąd typu "model qwen3-coder not found"

Przyczyna: Model nie jest pobrany

Rozwiązanie:
  ollama pull qwen3-coder
  (poczekaj aż się pobierze)

Jeśli nie masz miejsca na dysku:
  ollama pull devstral-small
  (mniejszy model, ale nadal działa)
  
  Potem zmień alias:
  alias fast='aider --model ollama_chat/devstral-small --auto-commits --yes'
Problem: AI pisze zły kod
text

Objaw:  Kod nie działa, ma błędy, nie robi tego co chcesz

Rozwiązanie 1 — Cofnij i sprecyzuj:
  > /undo
  > stwórz formularz logowania z DWOMA polami: 
  > email (musi zawierać @) i hasło (minimum 8 znaków).
  > Użyj HTML i CSS. Bez JavaScript.

  WSKAZÓWKA: Im dokładniej opiszesz co chcesz,
  tym lepszy kod dostaniesz.

Rozwiązanie 2 — Użyj lepszego modelu:
  /exit
  think
  > (powtórz zadanie)

Rozwiązanie 3 — Użyj heal (automatyczne):
  /exit
  heal "dokładny opis zadania"
Problem: "API key not set"
text

Objaw:  Błąd przy próbie użycia cloud modelu (cloud, smart)

Przyczyna: Nie skonfigurowałeś kluczy API

Rozwiązanie:
  Opcja A — Nie używaj cloud, zostań na Ollama:
    Używaj TYLKO: fast, think, quick
    Te komendy NIE potrzebują kluczy API!

  Opcja B — Skonfiguruj klucze:
    nano ~/.cascade/.env
    (wpisz swoje klucze, zapisz)
    source ~/.zshrc
Problem: Komputer się przegrzewa / spowalnia
text

Objaw:  Wentylator hałasuje, laptop jest gorący

Przyczyna: AI model zużywa dużo CPU/GPU

Rozwiązanie:
  1. Użyj mniejszego modelu:
     quick  (zamiast fast)
     
  2. Nie uruchamiaj wielu instancji Aider naraz
  
  3. Po skończeniu pracy:
     brew services stop ollama
     (uruchomisz ponownie następnego dnia)
Problem: Nie wiem co wpisać
text

Nie martw się! Oto gotowe szablony:

TWORZENIE STRONY:
> stwórz prostą stronę HTML z nagłówkiem "Moja Strona", 
> menu nawigacyjnym (Home, O nas, Kontakt) 
> i stopką z rokiem 2026

TWORZENIE API:
> stwórz prosty serwer Python Flask z endpointem 
> GET /users który zwraca listę 3 użytkowników jako JSON

POPRAWIANIE KODU:
> w pliku app.py jest błąd — funkcja calculate_total 
> nie obsługuje pustej listy. Napraw to i dodaj test.

WYJAŚNIENIE:
(użyj 'think' zamiast 'fast')
> wyjaśnij mi kod w pliku server.js 
> — co robi każda funkcja?

REFAKTORYZACJA:
> plik utils.py ma 500 linii. Podziel go na mniejsze pliki:
> string_utils.py, math_utils.py, file_utils.py
WSKAZÓWKI DLA POCZĄTKUJĄCYCH
Złote zasady pracy z AI
text

ZASADA 1: Bądź konkretny
  ❌ ŹLE:  "zrób stronę"
  ✅ DOBRZE: "stwórz stronę HTML z formularzem kontaktowym 
             zawierającym pola: imię, email, wiadomość 
             i przycisk Wyślij"

ZASADA 2: Jedno zadanie na raz
  ❌ ŹLE:  "stwórz całą aplikację e-commerce z koszykiem,
            płatnościami, kontem użytkownika i panelem admina"
  ✅ DOBRZE: "stwórz stronę główną sklepu z listą produktów"
             (potem osobno) "dodaj koszyk"
             (potem osobno) "dodaj formularz zamówienia"

ZASADA 3: Sprawdzaj po każdym kroku
  Po każdej zmianie AI:
  1. Otwórz zmieniony plik w VS Code
  2. Przeczytaj co AI napisał
  3. Jeśli wygląda OK → kontynuuj
  4. Jeśli nie → /undo i sprecyzuj

ZASADA 4: Nie bój się /undo
  AI ZAWSZE commituje zmiany do git.
  Zawsze możesz cofnąć. Nic nie stracisz.

ZASADA 5: Zacznij od prostych rzeczy
  Pierwszy projekt niech będzie PROSTY:
  - Strona HTML ze stylami CSS
  - Prosta aplikacja "lista zadań"
  - Kalkulator w Python
  Potem stopniowo zwiększaj trudność.
Jak rozmawiać z AI — przykłady
text

ZAMIAST:                        NAPISZ:
─────────────────────────────────────────────────────────
"zrób CSS"                      "dodaj CSS: niebieski nagłówek,
                                białe tło, czcionka Arial, 
                                przyciski z zaokrąglonymi rogami"

"napraw to"                     "w pliku login.js linia 42
                                jest błąd TypeError — 
                                zmienna user może być null,
                                dodaj sprawdzenie"

"dodaj bazę danych"             "dodaj SQLite bazę danych 
                                z tabelą users (id, name, email)
                                i funkcjami: dodaj_usera, 
                                pobierz_userow, usuń_usera"

"zrób ładniej"                  "popraw wygląd strony:
                                - wycentruj zawartość
                                - dodaj padding 20px
                                - nagłówek: niebieski, duży
                                - dodaj cień pod kartami"
BEZPIECZEŃSTWO — Ważne zasady
text

╔═══════════════════════════════════════════════════════════╗
║  ⚠️  ZAPAMIĘTAJ TE ZASADY                                ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  1. NIGDY nie wklejaj haseł, kluczy API,                 ║
║     ani danych osobowych do czatu z AI.                   ║
║     AI może je zapamiętać lub wysłać do chmury.           ║
║                                                           ║
║  2. Klucze API trzymaj TYLKO w pliku:                     ║
║     ~/.cascade/.env                                       ║
║     Ten plik jest automatycznie ignorowany przez git.     ║
║                                                           ║
║  3. Ollama = BEZPIECZNA (działa lokalnie)                 ║
║     Nic nie wysyła w internet.                            ║
║     Komendy: fast, think, quick — w pełni prywatne.      ║
║                                                           ║
║  4. Cloud modele (cloud, smart) WYSYŁAJĄ Twój kod        ║
║     do zewnętrznych serwerów.                             ║
║     Nie używaj ich z kodem zawierającym tajne dane.       ║
║                                                           ║
║  5. Przed publikacją kodu (np. na GitHub):                ║
║     Sprawdź czy nie ma w nim haseł/kluczy!                ║
║     git diff   ← pokaże co się zmieniło                   ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
CO DALEJ — Następne kroki
text

TYDZIEŃ 1: Podstawy
├── Dzień 1-2: Zainstaluj wszystko (ten przewodnik)
├── Dzień 3-4: Stwórz prostą stronę HTML z 'fast'
├── Dzień 5-6: Spróbuj 'heal' na trudniejszym zadaniu
└── Dzień 7: Sprawdź nocny raport (cat ~/.cascade/logs/nightly-*.log)

TYDZIEŃ 2: Praktyka
├── Stwórz prosty projekt Python (kalkulator, lista zadań)
├── Naucz się używać /undo i /add
├── Spróbuj 'think' do wyjaśniania koncepcji
└── Zarejestruj się na OpenRouter (darmowy cloud backup)

TYDZIEŃ 3: Zaawansowane
├── Stwórz projekt z testami (AI napisze testy za Ciebie)
├── Użyj 'cascade-init --react' dla projektu React
├── Edytuj AGENTS.md aby AI lepiej rozumiał Twój projekt
└── Sprawdź 'tokens' — jak wyglądają Twoje statystyki?

MIESIĄC 2+: Ekspert
├── Dostosuj AGENTS.md do swoich potrzeb
├── Eksperymentuj z różnymi modelami
├── Użyj autoresearch do optymalizacji
└── Podziel się swoimi doświadczeniami
