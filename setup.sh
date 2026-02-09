#!/bin/bash

#===============================================================================
#  🐧 LINUX TREASURE HUNT - Setup Script
#  Un'avventura per imparare i comandi base di Linux!
#  
#  NOTA: Questo script NON richiede dipendenze esterne!
#        Le dipendenze (unzip, gpg, htop) verranno installate dagli studenti
#        come parte delle sfide.
#===============================================================================

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directory dello script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/assets"

# Verifica esecuzione come root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Questo script deve essere eseguito con sudo!${NC}"
   echo "Usa: sudo ./setup.sh"
   exit 1
fi

# Verifica che gli assets esistano (5 ZIP + 1 GPG)
REQUIRED_ZIPS=(
    "backup_system_core.zip"
    "data_dump_node7.zip"
    "encrypted_payload.zip"
    "kernel_snapshot_v2.zip"
    "memory_sector_dump.zip"
)

MISSING_FILES=()

for zip_file in "${REQUIRED_ZIPS[@]}"; do
    if [[ ! -f "$ASSETS_DIR/$zip_file" ]]; then
        MISSING_FILES+=("$zip_file")
    fi
done

if [[ ! -f "$ASSETS_DIR/final_mission.gpg" ]]; then
    MISSING_FILES+=("final_mission.gpg")
fi

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    echo -e "${RED}ERRORE: File assets mancanti!${NC}"
    echo "Mancano i seguenti file nella cartella 'assets':"
    for f in "${MISSING_FILES[@]}"; do
        echo "  - $f"
    done
    echo ""
    echo "Esegui prima: ./create_assets.sh"
    exit 1
fi

# Utente reale (non root)
REAL_USER=${SUDO_USER:-$USER}
REAL_HOME=$(eval echo ~$REAL_USER)

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║     🐧 LINUX TREASURE HUNT - Inizializzazione 🐧             ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

#-------------------------------------------------------------------------------
# Pool di vocaboli per nomi file realistici
#-------------------------------------------------------------------------------
VOCAB_PREFIXES=(
    "config" "cache" "temp" "data" "backup" "module" "driver" "service"
    "daemon" "proc" "sys" "init" "kernel" "shell" "env" "lib" "src"
    "core" "main" "base" "default" "custom" "local" "global" "node"
    "buffer" "queue" "stack" "heap" "pipe" "socket" "stream" "block"
    "vogon" "endor" "hoth" "tardis" "flux" "warp" "nebula" "photon"
    "pixel" "byte" "sector" "cluster" "frame" "packet" "segment"
    "gandalf" "frodo" "aragorn" "kenobi" "skywalker" "spock" "picard"
    "matrix" "neo" "morpheus" "trinity" "oracle" "cipher" "tank"
)

VOCAB_SUFFIXES=(
    "alpha" "beta" "gamma" "delta" "omega" "prime" "zero" "null"
    "master" "slave" "primary" "secondary" "backup" "mirror" "clone"
    "old" "new" "test" "prod" "dev" "stage" "live" "draft"
    "x86" "arm" "risc" "cisc" "mips" "sparc" "power" "quantum"
    "tcp" "udp" "http" "ftp" "ssh" "dns" "dhcp" "smtp"
)

EXTENSIONS=("txt" "dat" "log" "cfg" "tmp" "bak" "old" "conf" "sys" "inf")

#-------------------------------------------------------------------------------
# Funzioni utility
#-------------------------------------------------------------------------------

generate_filename() {
    local prefix=${VOCAB_PREFIXES[$RANDOM % ${#VOCAB_PREFIXES[@]}]}
    local suffix=${VOCAB_SUFFIXES[$RANDOM % ${#VOCAB_SUFFIXES[@]}]}
    local num=$((RANDOM % 99))
    local ext=${EXTENSIONS[$RANDOM % ${#EXTENSIONS[@]}]}
    echo "${prefix}_${suffix}${num}.${ext}"
}

get_random_joke() {
    # Usa SOLO il file locale - nessuna dipendenza da curl/jq
    if [[ -f "$SCRIPT_DIR/jokes_cache.txt" ]]; then
        # Metodo bash puro per scegliere riga random
        local lines=$(wc -l < "$SCRIPT_DIR/jokes_cache.txt")
        local random_line=$((RANDOM % lines + 1))
        sed -n "${random_line}p" "$SCRIPT_DIR/jokes_cache.txt"
    else
        echo "Questo non è l'indizio che cerchi... continua a esplorare!"
    fi
}

create_decoy_files() {
    local target_dir=$1
    local count=${2:-100}
    
    for ((i=1; i<=count; i++)); do
        local filename=$(generate_filename)
        while [[ -f "$target_dir/$filename" ]]; do
            filename=$(generate_filename)
        done
        echo "$(get_random_joke)" > "$target_dir/$filename"
    done
}

print_progress() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_step() {
    echo -e "${YELLOW}[*]${NC} $1"
}

#-------------------------------------------------------------------------------
# Pulizia preventiva
#-------------------------------------------------------------------------------
print_step "Pulizia ambiente precedente..."

rm -rf /opt/treasure_hunt 2>/dev/null || true
rm -rf /var/log/treasure 2>/dev/null || true
rm -rf /tmp/treasure_* 2>/dev/null || true
rm -rf /tmp/extracted 2>/dev/null || true
rm -f /tmp/.phantom_process.pid 2>/dev/null || true
rm -f /tmp/.treasure_phantom_runner.sh 2>/dev/null || true
rm -rf "$REAL_HOME/.treasure_config" 2>/dev/null || true
rm -f /etc/phantom_service.log 2>/dev/null || true

pkill -f "treasure_phantom" 2>/dev/null || true

print_progress "Ambiente pulito"

#-------------------------------------------------------------------------------
# Creazione struttura directory
#-------------------------------------------------------------------------------
print_step "Creazione struttura directory..."

mkdir -p /opt/treasure_hunt/{vault,archive,matrix,final}
mkdir -p /var/log/treasure/secrets
mkdir -p /tmp/treasure_workspace/databank
mkdir -p "$REAL_HOME/.treasure_config"

chown -R $REAL_USER:$REAL_USER "$REAL_HOME/.treasure_config"
chmod 755 /opt/treasure_hunt
chmod 755 /var/log/treasure

print_progress "Directory create"

#===============================================================================
# TAPPA 1: Filesystem e Navigazione
#===============================================================================
print_step "Configurazione Tappa 1 - Filesystem..."

INDIZIO1_FILE="$REAL_HOME/.treasure_config/mission_briefing.txt"

cat > "$INDIZIO1_FILE" << 'INDIZIO1'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 1                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  Benvenuto, aspirante Linux Master!                                           ║
║                                                                               ║
║  Prima di tutto, devi capire come è organizzato un sistema Linux.             ║
║  Il filesystem Linux è come un albero rovesciato:                             ║
║                                                                               ║
║                              / (root)                                         ║
║                                 │                                             ║
║         ┌──────┬──────┬────────┼────────┬──────┬──────┐                       ║
║        /bin  /etc   /home     /var    /tmp   /opt   /usr                      ║
║                                                                               ║
║  📁 /bin    → Comandi essenziali (ls, cat, cp...)                             ║
║  📁 /etc    → File di CONFIGURAZIONE del sistema                              ║
║  📁 /home   → Directory personali degli utenti                                ║
║  📁 /var    → Dati variabili (log, cache, spool...)                           ║
║  📁 /tmp    → File temporanei                                                 ║
║  📁 /opt    → Software opzionale/aggiuntivo                                   ║
║  📁 /usr    → Programmi e librerie utente                                     ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  Qualcuno ha messo un file di LOG dove NON dovrebbe stare!                    ║
║  I file di log appartengono a /var/log, non altrove...                        ║
║                                                                               ║
║  COMANDI UTILI:                                                               ║
║  • cd <percorso>    → Cambia directory (es: cd /etc)                          ║
║  • ls               → Lista file nella directory corrente                     ║
║  • ls -la           → Lista TUTTI i file (anche nascosti) con dettagli       ║
║  • pwd              → Mostra dove ti trovi                                    ║
║  • cat <file>       → Mostra contenuto di un file                             ║
║                                                                               ║
║  💡 SUGGERIMENTO: Cerca un file .log in una directory dove non dovrebbe       ║
║     essere... Prova a esplorare /etc!                                         ║
║                                                                               ║
║  Usa: ls /etc | grep log                                                      ║
║       oppure esplora manualmente con cd e ls                                  ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
INDIZIO1

# File fuori posto in /etc
MISPLACED_FILE="/etc/phantom_service.log"
cat > "$MISPLACED_FILE" << 'MISPLACED'
═══════════════════════════════════════════════════════════════════════════════
📍 Hai trovato il file fuori posto! Bravo!

Un file .log in /etc? Assurdo! I log vanno in /var/log!

Il prossimo indizio ti aspetta... ma dovrai CONCATENARE per trovarlo!

VAI IN: /opt/treasure_hunt/vault

Lì troverai due file che insieme formano il prossimo indizio.
I loro nomi iniziano con "frag_" ... ma non è così semplice trovarli!

═══════════════════════════════════════════════════════════════════════════════
MISPLACED

chown $REAL_USER:$REAL_USER "$INDIZIO1_FILE"
chmod 644 "$MISPLACED_FILE"

print_progress "Tappa 1 configurata"

#===============================================================================
# TAPPA 2: cat e concatenazione
#===============================================================================
print_step "Configurazione Tappa 2 - Concatenazione..."

VAULT_DIR="/opt/treasure_hunt/vault"

create_decoy_files "$VAULT_DIR" 80

FRAG1_NAME="frag_$(generate_filename | cut -d'.' -f1).dat"
FRAG2_NAME="frag_$(generate_filename | cut -d'.' -f1).dat"

# Assicuriamoci che siano in ordine alfabetico corretto
if [[ "$FRAG1_NAME" > "$FRAG2_NAME" ]]; then
    TEMP="$FRAG1_NAME"
    FRAG1_NAME="$FRAG2_NAME"
    FRAG2_NAME="$TEMP"
fi

cat > "$VAULT_DIR/$FRAG1_NAME" << 'FRAG1'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 2                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  Il comando CAT (concatenate) è uno dei più usati in Linux!                   ║
║                                                                               ║
║  UTILIZZI PRINCIPALI:                                                         ║
║  • cat file.txt           → Mostra il contenuto di un file                    ║
║  • cat file1 file2        → Mostra il contenuto di più file in sequenza       ║
║  • cat file1 file2 > new  → Concatena e salva in un nuovo file                ║
║                                                                               ║
║  Il nome "cat" viene da "concatenate" (concatenare), perché permette          ║
║  di unire più file insieme!                                                   ║
║                                                                               ║
FRAG1

cat > "$VAULT_DIR/$FRAG2_NAME" << 'FRAG2'
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 HAI CONCATENATO CORRETTAMENTE!                                            ║
║                                                                               ║
║  Il prossimo indizio richiede di usare le WILDCARD e il comando FIND!         ║
║                                                                               ║
║  VAI IN: /opt/treasure_hunt/matrix                                            ║
║                                                                               ║
║  Lì ci sono molti file. Alcuni hanno nomi che, messi insieme, formano         ║
║  il percorso del prossimo indizio. Cerca i file che iniziano con "path_"      ║
║  e ordina i loro nomi per trovare la strada!                                  ║
║                                                                               ║
║  USA: ls path_* oppure find . -name "path_*" | sort                           ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
FRAG2

cat > "$VAULT_DIR/README_vault.txt" << HINT
Questa directory contiene molti file...
Due di loro iniziano con "frag_" e vanno concatenati con: cat frag_* 
Ma attenzione all'ORDINE! Usa: ls frag_* | sort  per vedere l'ordine giusto
poi: cat \$(ls frag_* | sort)
HINT

print_progress "Tappa 2 configurata"

#===============================================================================
# TAPPA 3: Wildcard e Find
#===============================================================================
print_step "Configurazione Tappa 3 - Wildcard..."

MATRIX_DIR="/opt/treasure_hunt/matrix"

create_decoy_files "$MATRIX_DIR" 100

cat > "$MATRIX_DIR/path_1_alpha.txt" << 'EOF'
/var
EOF

cat > "$MATRIX_DIR/path_2_beta.txt" << 'EOF'
/log
EOF

cat > "$MATRIX_DIR/path_3_gamma.txt" << 'EOF'
/treasure
EOF

cat > "$MATRIX_DIR/path_4_delta.txt" << 'EOF'
/secrets
EOF

cat > "$MATRIX_DIR/README_matrix.txt" << 'MATRIXREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 3                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  Le WILDCARD sono caratteri speciali che rappresentano altri caratteri:       ║
║                                                                               ║
║  • *     → Rappresenta QUALSIASI sequenza di caratteri (anche vuota)          ║
║  • ?     → Rappresenta UN SINGOLO carattere qualsiasi                         ║
║  • [abc] → Rappresenta UNO dei caratteri tra parentesi                        ║
║                                                                               ║
║  ESEMPI:                                                                      ║
║  • ls *.txt        → Tutti i file che finiscono con .txt                      ║
║  • ls file?.dat    → file1.dat, fileA.dat, ma NON file12.dat                  ║
║  • ls [abc]*       → Tutti i file che iniziano con a, b, o c                  ║
║                                                                               ║
║  IL COMANDO FIND:                                                             ║
║  • find /percorso -name "pattern"    → Cerca file per nome                    ║
║  • find . -name "*.txt"              → Cerca tutti i .txt da qui in giù       ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  In questa directory ci sono file che iniziano con "path_".                   ║
║  Ognuno contiene UNA PARTE del percorso verso il prossimo indizio!            ║
║                                                                               ║
║  1. Trova tutti i file: ls path_*                                             ║
║  2. Ordinali: ls path_* | sort                                                ║
║  3. Leggi il contenuto in ordine: cat $(ls path_* | sort)                     ║
║  4. Unisci le parti per ottenere il percorso!                                 ║
║                                                                               ║
║  💡 Il percorso risultante ti porterà alla prossima sfida!                    ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
MATRIXREADME

print_progress "Tappa 3 configurata"

#===============================================================================
# TAPPA 4: Permessi
#===============================================================================
print_step "Configurazione Tappa 4 - Permessi..."

SECRETS_DIR="/var/log/treasure/secrets"

create_decoy_files "$SECRETS_DIR" 50

INDIZIO4_NAME=$(generate_filename)
cat > "$SECRETS_DIR/$INDIZIO4_NAME" << 'INDIZIO4'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 5                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  🎉 HAI SBLOCCATO IL FILE! Ottimo lavoro con i permessi!                      ║
║                                                                               ║
║  Ora è il momento di investigare i PROCESSI del sistema...                    ║
║                                                                               ║
║  Installa HTOP per una visualizzazione migliore:                              ║
║  → sudo apt update && sudo apt install htop -y                                ║
║                                                                               ║
║  Un processo MISTERIOSO sta girando in background sul sistema!                ║
║  Il suo PID è salvato in: /tmp/.phantom_process.pid                           ║
║                                                                               ║
║  1. Leggi il PID: cat /tmp/.phantom_process.pid                               ║
║  2. Verifica il processo: ps aux | grep <PID>                                 ║
║     oppure cercalo in htop                                                    ║
║  3. Termina il processo: kill <PID>                                           ║
║  4. Controlla i LOG in /var/log/treasure/ per il prossimo indizio!            ║
║                                                                               ║
║  💡 Il comando KILL invia segnali ai processi.                                ║
║     kill <PID>      → Termina gentilmente (SIGTERM)                           ║
║     kill -9 <PID>   → Termina forzatamente (SIGKILL)                          ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
INDIZIO4

chmod 000 "$SECRETS_DIR/$INDIZIO4_NAME"

cat > "/var/log/treasure/secrets/README_secrets.txt" << 'PERMREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 4                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  I PERMESSI in Linux controllano chi può fare cosa con i file!                ║
║                                                                               ║
║  Ogni file ha 3 tipi di permessi per 3 categorie:                             ║
║                                                                               ║
║  TIPI:        r (read)    → Leggere il file                                   ║
║               w (write)   → Modificare il file                                ║
║               x (execute) → Eseguire il file                                  ║
║                                                                               ║
║  CATEGORIE:   u (user)    → Il proprietario                                   ║
║               g (group)   → Il gruppo                                         ║
║               o (others)  → Tutti gli altri                                   ║
║                                                                               ║
║  ESEMPIO: -rwxr-xr--                                                          ║
║           │└┬┘└┬┘└┬┘                                                          ║
║           │ │  │  └── others: r-- (solo lettura)                              ║
║           │ │  └───── group:  r-x (lettura + esecuzione)                      ║
║           │ └──────── user:   rwx (tutti i permessi)                          ║
║           └────────── tipo di file (- = file normale)                         ║
║                                                                               ║
║  COMANDI:                                                                     ║
║  • ls -la              → Mostra i permessi                                    ║
║  • chmod +r file       → Aggiunge permesso di lettura                         ║
║  • chmod u+rwx file    → Aggiunge tutti i permessi al proprietario            ║
║  • chmod 644 file      → Imposta permessi in notazione ottale                 ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  In questa directory c'è un file che NON puoi leggere (permessi 000).         ║
║  Devi trovarlo e sbloccare i permessi di lettura!                             ║
║                                                                               ║
║  1. Elenca i file con dettagli: ls -la                                        ║
║  2. Cerca quello con "----------" (nessun permesso)                           ║
║  3. Aggiungi il permesso di lettura: sudo chmod +r <nomefile>                 ║
║  4. Leggi il contenuto: cat <nomefile>                                        ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
PERMREADME

print_progress "Tappa 4 configurata"

#===============================================================================
# TAPPA 5: Processi e Kill
#===============================================================================
print_step "Configurazione Tappa 5 - Processi..."

PHANTOM_SCRIPT="/tmp/.treasure_phantom_runner.sh"
cat > "$PHANTOM_SCRIPT" << 'PHANTOM'
#!/bin/bash

LOG_FILE="/var/log/treasure/phantom_output.log"

cleanup() {
    echo "" >> "$LOG_FILE"
    echo "═══════════════════════════════════════════════════════════════════════════════" >> "$LOG_FILE"
    echo "📍 PROCESSO TERMINATO! Hai trovato l'indizio!" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "Il prossimo indizio richiede di usare GREP con le PIPE!" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "VAI IN: /tmp/treasure_workspace/databank" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "Lì troverai MOLTI file. Devi cercare quello che CONTIENE" >> "$LOG_FILE"
    echo "la parola 'NEXUS' al suo interno!" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "USA: grep -l \"NEXUS\" * oppure grep -r \"NEXUS\" ." >> "$LOG_FILE"
    echo "═══════════════════════════════════════════════════════════════════════════════" >> "$LOG_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

while true; do
    sleep 1
done
PHANTOM

chmod +x "$PHANTOM_SCRIPT"

nohup bash -c "exec -a 'treasure_phantom_process' $PHANTOM_SCRIPT" > /dev/null 2>&1 &
PHANTOM_PID=$!

echo "$PHANTOM_PID" > /tmp/.phantom_process.pid
chmod 644 /tmp/.phantom_process.pid

print_progress "Tappa 5 configurata (Phantom PID: $PHANTOM_PID)"

#===============================================================================
# TAPPA 6: Grep e Pipe
#===============================================================================
print_step "Configurazione Tappa 6 - Grep..."

DATABANK_DIR="/tmp/treasure_workspace/databank"

create_decoy_files "$DATABANK_DIR" 120

NEXUS_FILE="$DATABANK_DIR/$(generate_filename)"
cat > "$NEXUS_FILE" << 'NEXUS'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 7                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  NEXUS TROVATO! Ottimo uso di grep!                                           ║
║                                                                               ║
║  Ora devi ESTRARRE dei file compressi!                                        ║
║                                                                               ║
║  Prima installa unzip se non è presente:                                      ║
║  → sudo apt install unzip -y                                                  ║
║                                                                               ║
║  In /tmp/treasure_workspace/ ci sono 5 ARCHIVI ZIP!                           ║
║  Solo UNO contiene il vero indizio... gli altri sono trappole! 😈             ║
║                                                                               ║
║  COMANDI UTILI:                                                               ║
║  • ls /tmp/treasure_workspace/*.zip      → Vedi tutti gli archivi             ║
║  • unzip file.zip -d /tmp/dest           → Estrai in una cartella             ║
║  • unzip -l file.zip                     → Vedi contenuto SENZA estrarre      ║
║                                                                               ║
║  SUGGERIMENTO: Estrai tutto in cartelle separate e poi esplora!               ║
║                                                                               ║
║  mkdir /tmp/estratti                                                          ║
║  for f in /tmp/treasure_workspace/*.zip; do                                   ║
║      unzip "$f" -d "/tmp/estratti/$(basename $f .zip)"                        ║
║  done                                                                         ║
║                                                                               ║
║  Oppure uno alla volta... la scelta è tua!                                    ║
║                                                                               ║
║  💡 Cerca file di testo con: find /tmp/estratti -name "*.txt" -o -name "*.cfg"║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
NEXUS
cat > "$DATABANK_DIR/README_databank.txt" << 'GREPREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 6                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  GREP è uno strumento POTENTISSIMO per cercare testo nei file!                ║
║                                                                               ║
║  SINTASSI BASE:                                                               ║
║  • grep "pattern" file      → Cerca "pattern" nel file                        ║
║  • grep "pattern" *         → Cerca in tutti i file della directory           ║
║  • grep -r "pattern" .      → Cerca RICORSIVAMENTE in tutte le subdirectory   ║
║  • grep -l "pattern" *      → Mostra solo i NOMI dei file che contengono      ║
║  • grep -i "pattern" file   → Ricerca case-INSENSITIVE                        ║
║                                                                               ║
║  LE PIPE ( | ):                                                               ║
║  Le pipe connettono l'output di un comando all'input di un altro!             ║
║                                                                               ║
║  ESEMPI:                                                                      ║
║  • ls -la | grep ".txt"     → Lista file e filtra solo quelli con .txt        ║
║  • cat file | grep "word"   → Mostra solo le righe che contengono "word"      ║
║  • ps aux | grep firefox    → Mostra solo i processi firefox                  ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  In questa directory c'è UN file che contiene la parola "NEXUS".              ║
║  Trovalo usando grep!                                                         ║
║                                                                               ║
║  USA: grep -l "NEXUS" *                                                       ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
GREPREADME

print_progress "Tappa 6 configurata"

#===============================================================================
# TAPPA 7: Unzip (copia file pre-generati - TUTTI E 5!)
#===============================================================================
print_step "Configurazione Tappa 7 - Archivi ZIP..."

# Copia TUTTI gli archivi ZIP nella workspace
cp "$ASSETS_DIR"/*.zip /tmp/treasure_workspace/

print_progress "Tappa 7 configurata (5 archivi ZIP copiati)"

#===============================================================================
# TAPPA 8: Hash
#===============================================================================
print_step "Configurazione Tappa 8 - Hash..."

ARCHIVE_DIR="/opt/treasure_hunt/archive"

create_decoy_files "$ARCHIVE_DIR" 60

HASH_INDIZIO_FILE="$ARCHIVE_DIR/$(generate_filename)"
cat > "$HASH_INDIZIO_FILE" << 'HASHINDIZIO'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 9                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  🎉 HASH CORRETTO! Sei quasi alla fine!                                       ║
║                                                                               ║
║  La penultima sfida: trovare la PASSWORD per l'indizio finale!                ║
║                                                                               ║
║  Da qualche parte nel sistema c'è un file che contiene una password...        ║
║  È nascosto bene! Usa tutto quello che hai imparato:                          ║
║                                                                               ║
║  • find per cercare file                                                      ║
║  • grep per cercare contenuti                                                 ║
║                                                                               ║
║  💡 SUGGERIMENTO: La password è in un file che contiene "QUANTUM_KEY"         ║
║     Cerca in tutto il sistema: sudo grep -r "QUANTUM_KEY" / 2>/dev/null       ║
║     (il 2>/dev/null nasconde gli errori di permesso)                          ║
║                                                                               ║
║  Una volta trovata la password, vai in: /opt/treasure_hunt/final              ║
║                                                                               ║
║  Lì c'è un file .gpg da decriptare con:                                       ║
║  → gpg -d final_mission.gpg                                                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
HASHINDIZIO

TARGET_HASH=$(md5sum "$HASH_INDIZIO_FILE" | cut -d' ' -f1)

cat > "$ARCHIVE_DIR/target_hash.txt" << TARGETHASH
╔═══════════════════════════════════════════════════════════════════════════════╗
║                     🔐 SFIDA HASH - TROVA IL FILE!                            ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  L'hash MD5 del file che cerchi è:                                            ║
║                                                                               ║
║  → $TARGET_HASH                                                ║
║                                                                               ║
║  Uno dei file in questa directory ha questo hash.                             ║
║  Trovalo!                                                                     ║
║                                                                               ║
║  COMANDO: md5sum * 2>/dev/null | grep "$TARGET_HASH"           ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
TARGETHASH

print_progress "Tappa 8 configurata"

#===============================================================================
# TAPPA 9: Trova Password
#===============================================================================
print_step "Configurazione Tappa 9 - Password nascosta..."

PASSWORD_HIDDEN_DIR="/var/cache"
mkdir -p "$PASSWORD_HIDDEN_DIR" 2>/dev/null || true

PASSWORD_FILE="$PASSWORD_HIDDEN_DIR/.quantum_cache_$(generate_filename | cut -d'.' -f1).dat"
cat > "$PASSWORD_FILE" << 'PWDFILE'
═══════════════════════════════════════════════════════════════════════════════
QUANTUM_KEY FOUND!

La password per decriptare il file finale è:

    LinuxMaster2024!

Vai in /opt/treasure_hunt/final e usa:
    gpg -d final_mission.gpg

Quando chiede la password, inserisci: LinuxMaster2024!
═══════════════════════════════════════════════════════════════════════════════
PWDFILE

chmod 644 "$PASSWORD_FILE"

print_progress "Tappa 9 configurata"

#===============================================================================
# TAPPA 10: Finale GPG (copia file pre-generato)
#===============================================================================
print_step "Configurazione Tappa 10 - Finale GPG..."

FINAL_DIR="/opt/treasure_hunt/final"

cp "$ASSETS_DIR/final_mission.gpg" "$FINAL_DIR/"

cat > "$FINAL_DIR/README_final.txt" << 'FINALREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - TAPPA FINALE                      ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  GPG (GNU Privacy Guard) è uno strumento per crittografare file!              ║
║                                                                               ║
║  COMANDI BASE:                                                                ║
║  • gpg -c file           → Cripta un file (chiede password)                   ║
║  • gpg -d file.gpg       → Decripta un file (chiede password)                 ║
║  • gpg -o output -d file → Decripta e salva in un file                        ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 MISSIONE FINALE:                                                          ║
║                                                                               ║
║  Il file "final_mission.gpg" contiene il messaggio finale.                    ║
║  Hai trovato la password nella tappa precedente?                              ║
║                                                                               ║
║  USA: gpg -d final_mission.gpg                                                ║
║                                                                               ║
║  Inserisci la password quando richiesto!                                      ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
FINALREADME

print_progress "Tappa 10 configurata"

#===============================================================================
# Finalizzazione
#===============================================================================
print_step "Finalizzazione..."

chown -R $REAL_USER:$REAL_USER /tmp/treasure_workspace 2>/dev/null || true
chmod -R 755 /opt/treasure_hunt

echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                               ║"
echo "║     🎉 SETUP COMPLETATO CON SUCCESSO! 🎉                                      ║"
echo "║                                                                               ║"
echo "╠═══════════════════════════════════════════════════════════════════════════════╣"
echo "║                                                                               ║"
echo "║     La caccia al tesoro è pronta!                                             ║"
echo "║                                                                               ║"
echo "║     📍 PRIMO INDIZIO: ~/.treasure_config/mission_briefing.txt                 ║"
echo "║                                                                               ║"
echo "║     Per iniziare, esegui:                                                     ║"
echo "║     cat ~/.treasure_config/mission_briefing.txt                               ║"
echo "║                                                                               ║"
echo "║     Buona fortuna, aspirante Linux Master! 🐧                                 ║"
echo "║                                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
