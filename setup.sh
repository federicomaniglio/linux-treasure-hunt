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

# Verifica che gli assets esistano (5 ZIP + 1 final_clue.zip + 1 GPG)
REQUIRED_ZIPS=(
    "backup_system_core.zip"
    "data_dump_node7.zip"
    "encrypted_payload.zip"
    "kernel_snapshot_v2.zip"
    "memory_sector_dump.zip"
    "final_clue.zip"
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

mkdir -p /opt/treasure_hunt/{vault,archive,matrix,final,backup}
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
║  Il filesystem Linux è organizzato come un albero che parte da "/" (root).    ║
║  Ogni directory ha uno SCOPO PRECISO:                                         ║
║                                                                               ║
║                              / (root)                                         ║
║                                 │                                             ║
║         ┌──────┬──────┬────────┼────────┬──────┬──────┐                       ║
║        /bin  /etc   /home     /var    /tmp   /opt   /usr                      ║
║                                                                               ║
║  📁 /bin    → Comandi e binari eseguibili essenziali del sistema              ║
║  📁 /etc    → File di CONFIGURAZIONE (.conf, .cfg, .ini...)                   ║
║  📁 /home   → Directory personali degli utenti                                ║
║  📁 /var    → Dati variabili: LOG di sistema, cache, spool...                 ║
║  📁 /tmp    → File temporanei                                                 ║
║  📁 /opt    → Software opzionale                                              ║
║  📁 /usr    → Programmi e librerie utente                                     ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  Qualcuno ha nascosto dei file nel sistema, ma uno di questi è finito        ║
║  nella directory SBAGLIATA!                                                   ║
║                                                                               ║
║  Esplora il filesystem e trova l'intruso. Pensa: che tipo di file            ║
║  dovrebbe contenere ogni directory?                                           ║
║                                                                               ║
║  COMANDI UTILI:                                                               ║
║  • cd        → Cambia directory                                               ║
║  • ls        → Elenca i file                                                  ║
║  • ls -la    → Elenca TUTTI i file con dettagli                               ║
║  • pwd       → Mostra la directory corrente                                   ║
║  • nano file → Apre un file per visualizzarlo/modificarlo (CTRL+X per uscire) ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
INDIZIO1

chown $REAL_USER:$REAL_USER "$INDIZIO1_FILE"

# Crea cartelle lab/ in diverse directory di sistema

# /bin/lab/ - script e binari eseguibili (CORRETTI)
mkdir -p /bin/lab
cat > /bin/lab/check_system.sh << 'BINSCRIPT'
#!/bin/bash
echo "System check: OK"
BINSCRIPT
chmod +x /bin/lab/check_system.sh
cat > /bin/lab/monitor.sh << 'BINSCRIPT2'
#!/bin/bash
echo "Monitoring active..."
BINSCRIPT2
chmod +x /bin/lab/monitor.sh
echo '#!/bin/bash' > /bin/lab/helper.sh
echo 'echo "Helper utility"' >> /bin/lab/helper.sh
chmod +x /bin/lab/helper.sh

# /etc/lab/ - file di configurazione (CORRETTI) + IL FILE FUORI POSTO
mkdir -p /etc/lab
echo "# Database configuration" > /etc/lab/database.conf
echo "host=localhost" >> /etc/lab/database.conf
echo "port=5432" >> /etc/lab/database.conf
echo "# Network settings" > /etc/lab/network.cfg
echo "interface=eth0" >> /etc/lab/network.cfg
echo "# System parameters" > /etc/lab/system.ini
echo "[main]" >> /etc/lab/system.ini
echo "debug=false" >> /etc/lab/system.ini
echo "[settings]" > /etc/lab/app_config.conf
echo "theme=dark" >> /etc/lab/app_config.conf

# IL FILE FUORI POSTO: un .log in /etc/lab/ (dovrebbe essere in /var!)
cat > "/etc/lab/phantom_service.log" << 'MISPLACED'
═══════════════════════════════════════════════════════════════════════════════
📍 Hai trovato il file fuori posto! Bravo!

Un file .log in /etc? I log appartengono a /var!
Hai capito la struttura del filesystem Linux!

Il prossimo indizio ti aspetta... ma dovrai CONCATENARE per trovarlo!

VAI IN: /opt/treasure_hunt/vault

In mezzo al caos, c'è sempre qualcuno pronto a darti una mano.
Basta sapere a chi chiedere... o cosa leggere.

═══════════════════════════════════════════════════════════════════════════════
MISPLACED

# /var/lab/ - file di log e dati variabili (CORRETTI)
mkdir -p /var/lab
echo "[2024-01-15 10:23:45] System started" > /var/lab/system.log
echo "[2024-01-15 10:24:12] Service initialized" >> /var/lab/system.log
echo "[2024-01-15 10:30:00] Backup completed" > /var/lab/backup.log
echo "[2024-01-15 11:00:00] Scheduled task executed" >> /var/lab/backup.log
echo "cache_data_block_001" > /var/lab/cache.dat
echo "spool_queue_entry" > /var/lab/spool.dat

# /tmp/lab/ - file temporanei (CORRETTI)
mkdir -p /tmp/lab
echo "temporary data 12345" > /tmp/lab/session_001.tmp
echo "swap buffer content" > /tmp/lab/buffer.tmp
echo "processing queue" > /tmp/lab/process_queue.tmp
echo "temp calculation result" > /tmp/lab/calc.tmp

# /opt/lab/ - software opzionale (CORRETTI)
mkdir -p /opt/lab
echo "#!/bin/bash" > /opt/lab/custom_tool.sh
echo "echo 'Custom Lab Tool v1.0'" >> /opt/lab/custom_tool.sh
chmod +x /opt/lab/custom_tool.sh
echo "Application data v1.0" > /opt/lab/app_data.dat
echo "Plugin configuration" > /opt/lab/plugin.dat

# Imposta permessi
chmod 755 /bin/lab /etc/lab /var/lab /tmp/lab /opt/lab
chmod 644 /etc/lab/* /var/lab/* /tmp/lab/* /opt/lab/*.dat

print_progress "Tappa 1 configurata"
#===============================================================================
# TAPPA 2: cat e concatenazione
#===============================================================================
print_step "Configurazione Tappa 2 - Concatenazione..."

VAULT_DIR="/opt/treasure_hunt/vault"

create_decoy_files "$VAULT_DIR" 80

# Genera nomi per i frammenti (con prefisso fragment_ in inglese)
FRAG1_NAME="fragment_$(generate_filename | cut -d'.' -f1).dat"
FRAG2_NAME="fragment_$(generate_filename | cut -d'.' -f1).dat"

# Assicuriamoci che siano in ordine alfabetico corretto
if [[ "$FRAG1_NAME" > "$FRAG2_NAME" ]]; then
    TEMP="$FRAG1_NAME"
    FRAG1_NAME="$FRAG2_NAME"
    FRAG2_NAME="$TEMP"
fi

cat > "$VAULT_DIR/$FRAG1_NAME" << 'FRAG1'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              FRAMMENTO 1 di 2                                 ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  Ottimo lavoro! Hai trovato e concatenato i frammenti!                        ║
║                                                                               ║
║  Ricorda: CAT è utilissimo anche per leggere file velocemente.                ║
║  Invece di aprire nano o un editor, basta: cat nomefile                       ║
║                                                                               ║
║  Puoi anche concatenare con le wildcard:                                      ║
║  • cat fragment*   → Concatena tutti i file che iniziano con "fragment"       ║
║  • cat *.log       → Concatena tutti i file .log                              ║
║                                                                               ║
FRAG1

cat > "$VAULT_DIR/$FRAG2_NAME" << 'FRAG2'
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 PROSSIMA DESTINAZIONE:                                                    ║
║                                                                               ║
║  "Welcome to the Matrix, Neo..."                                              ║
║                                                                               ║
║  La prossima sfida ti attende in /opt/treasure_hunt/matrix                    ║
║                                                                               ║
║  Lì dovrai usare le WILDCARD per trovare dei file speciali.                   ║
║  Il loro contenuto, messo insieme, rivelerà il percorso successivo.           ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
FRAG2

cat > "$VAULT_DIR/README_vault.txt" << 'VAULTREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 2                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  Benvenuto nel VAULT! Qui imparerai il comando CAT.                           ║
║                                                                               ║
║  CAT (da "concatenate") è uno dei comandi più versatili di Linux:             ║
║  • cat file          → Mostra velocemente il contenuto di un file             ║
║  • cat file1 file2   → Mostra i file UNO DOPO L'ALTRO (concatenati)           ║
║  • cat *.txt         → Mostra tutti i file .txt concatenati                   ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  LE PIPE ( | ):                                                               ║
║  Il simbolo | (pipe) collega l'OUTPUT di un comando all'INPUT di un altro.    ║
║                                                                               ║
║  Esempio: ls | sort                                                           ║
║  → ls elenca i file, sort li ordina alfabeticamente                           ║
║                                                                               ║
║  Esempio: ls *.dat | sort                                                     ║
║  → Elenca solo i .dat e li ordina                                             ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  In questa cartella ci sono molti file, ma due di essi sono "fragments"       ║
║  (frammenti) di un messaggio spezzato in due parti.                           ║
║                                                                               ║
║  Il messaggio completo si ottiene CONCATENANDO i due frammenti nell'ordine    ║
║  alfabetico corretto. Trova i frammenti, ordinali e uniscili con cat!         ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
VAULTREADME

print_progress "Tappa 2 configurata"

#===============================================================================
# TAPPA 3: Wildcard e Find
#===============================================================================
print_step "Configurazione Tappa 3 - Wildcard..."

MATRIX_DIR="/opt/treasure_hunt/matrix"

create_decoy_files "$MATRIX_DIR" 100

# File che contengono le parti del percorso (nomi che NON rivelano l'ordine facilmente)
# Devono ordinarli loro per capire la sequenza
cat > "$MATRIX_DIR/coordinate_alpha.txt" << 'EOF'
/var
EOF

cat > "$MATRIX_DIR/coordinate_beta.txt" << 'EOF'
/log
EOF

cat > "$MATRIX_DIR/coordinate_gamma.txt" << 'EOF'
/treasure
EOF

cat > "$MATRIX_DIR/coordinate_delta.txt" << 'EOF'
/secrets
EOF

cat > "$MATRIX_DIR/README_matrix.txt" << 'MATRIXREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 3                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  "Benvenuto nella Matrix. Qui imparerai a vedere oltre il codice..."          ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  LE WILDCARD (caratteri jolly):                                               ║
║  Permettono di selezionare più file con un solo comando!                      ║
║                                                                               ║
║  • *        → Qualsiasi sequenza di caratteri (anche vuota)                   ║
║              ls *.txt      → tutti i file .txt                                ║
║              ls data*      → tutti i file che iniziano con "data"             ║
║                                                                               ║
║  • ?        → Esattamente UN carattere qualsiasi                              ║
║              ls file?.txt  → file1.txt, fileA.txt (ma NON file12.txt)         ║
║                                                                               ║
║  • [abc]    → Uno dei caratteri specificati                                   ║
║              ls file[123].txt → file1.txt, file2.txt, file3.txt               ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  IL COMANDO FIND - Cerca file nel filesystem:                                 ║
║                                                                               ║
║  • find /percorso -name "pattern"                                             ║
║    → Cerca file con quel nome nel percorso specificato                        ║
║                                                                               ║
║  • find . -name "*.conf"                                                      ║
║    → Cerca tutti i .conf dalla directory corrente in giù                      ║
║                                                                               ║
║  • find /home -name "report*"                                                 ║
║    → Cerca file che iniziano con "report" in /home                            ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  In questa cartella ci sono dei file "coordinate" nascosti tra tanti altri.   ║
║  Ognuno contiene un PEZZO di un percorso di sistema.                          ║
║                                                                               ║
║  Unendo i contenuti nell'ORDINE ALFABETICO dei nomi dei file,                 ║
║  otterrai il percorso della prossima destinazione.                            ║
║                                                                               ║
║  Usa le wildcard per trovarli e cat per leggerne il contenuto!                ║
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

# Il file con l'indizio (nome randomico, permessi 000)
INDIZIO4_NAME=$(generate_filename)
cat > "$SECRETS_DIR/$INDIZIO4_NAME" << 'INDIZIO4'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              🔓 FILE SBLOCCATO!                               ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  Ottimo lavoro con i permessi! Ora sai come funziona la sicurezza in Linux.   ║
║                                                                               ║
║  Ricorda la notazione ottale:                                                 ║
║  • 7 = rwx (4+2+1)  → lettura + scrittura + esecuzione                        ║
║  • 6 = rw- (4+2)    → lettura + scrittura                                     ║
║  • 5 = r-x (4+1)    → lettura + esecuzione                                    ║
║  • 4 = r-- (4)      → solo lettura                                            ║
║  • 0 = --- (0)      → nessun permesso                                         ║
║                                                                               ║
║  Esempio: chmod 755 file → rwxr-xr-x                                          ║
║           chmod 644 file → rw-r--r--                                          ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 PROSSIMA SFIDA: I PROCESSI                                                ║
║                                                                               ║
║  C'è un processo fantasma in esecuzione su questo sistema...                  ║
║                                                                               ║
║  VAI IN: /tmp                                                                 ║
║                                                                               ║
║  Cerca un file che inizia con un punto (file nascosto!) e leggi le istruzioni.║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
INDIZIO4

chmod 000 "$SECRETS_DIR/$INDIZIO4_NAME"

cat > "/var/log/treasure/secrets/README_secrets.txt" << 'PERMREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 4                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  I PERMESSI in Linux: il sistema di sicurezza fondamentale!                   ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  Ogni file ha 3 TIPI di permessi:                                             ║
║  • r (read)    → Permette di LEGGERE il contenuto                             ║
║  • w (write)   → Permette di MODIFICARE il file                               ║
║  • x (execute) → Permette di ESEGUIRE il file (se è uno script/programma)     ║
║                                                                               ║
║  E 3 CATEGORIE di utenti:                                                     ║
║  • u (user)    → Il PROPRIETARIO del file                                     ║
║  • g (group)   → Gli utenti del GRUPPO del file                               ║
║  • o (others)  → TUTTI GLI ALTRI                                              ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  COME LEGGERE I PERMESSI:                                                     ║
║                                                                               ║
║  Quando fai "ls -la" vedi qualcosa tipo: -rwxr-xr--                           ║
║                                                                               ║
║     -    rwx    r-x    r--                                                    ║
║     │     │      │      │                                                     ║
║     │     │      │      └── others: può solo leggere                          ║
║     │     │      └───────── group: può leggere ed eseguire                    ║
║     │     └──────────────── user: può fare tutto                              ║
║     └────────────────────── tipo (- = file, d = directory)                    ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  IL COMANDO CHMOD - Cambia i permessi:                                        ║
║                                                                               ║
║  Sintassi simbolica:                                                          ║
║  • chmod +r file     → Aggiunge lettura a tutti                               ║
║  • chmod u+x file    → Aggiunge esecuzione al proprietario                    ║
║  • chmod go-w file   → Rimuove scrittura a group e others                     ║
║                                                                               ║
║  Sintassi ottale (numeri):                                                    ║
║  • chmod 644 file    → rw-r--r-- (comune per file)                            ║
║  • chmod 755 file    → rwxr-xr-x (comune per script)                          ║
║  • chmod 600 file    → rw------- (file privato)                               ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  Tra i tanti file in questa directory, ce n'è uno "blindato"!                 ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
PERMREADME

print_progress "Tappa 4 configurata"
#===============================================================================
# TAPPA 5: Processi e Kill
#===============================================================================
print_step "Configurazione Tappa 5 - Processi..."

# Salva il percorso della home per lo script del phantom
PHANTOM_SCRIPT="/tmp/.treasure_phantom_runner.sh"
cat > "$PHANTOM_SCRIPT" << PHANTOM
#!/bin/bash

LOG_FILE="/var/log/treasure/phantom_output.log"
PASSWORD_FILE="$REAL_HOME/.treasure_config/.final_secret"

cleanup() {
    # Crea il file con la password nella cartella dell'indizio 1
    echo "" > "\$PASSWORD_FILE"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗" >> "\$PASSWORD_FILE"
    echo "║                        🔑 MESSAGGIO DAL FANTASMA                              ║" >> "\$PASSWORD_FILE"
    echo "╠═══════════════════════════════════════════════════════════════════════════════╣" >> "\$PASSWORD_FILE"
    echo "║                                                                               ║" >> "\$PASSWORD_FILE"
    echo "║  Mi hai trovato e ucciso... ma ti lascio un regalo!                           ║" >> "\$PASSWORD_FILE"
    echo "║                                                                               ║" >> "\$PASSWORD_FILE"
    echo "║  La password per decriptare il messaggio finale è:                            ║" >> "\$PASSWORD_FILE"
    echo "║                                                                               ║" >> "\$PASSWORD_FILE"
    echo "║                         I love TPSIT                                          ║" >> "\$PASSWORD_FILE"
    echo "║                                                                               ║" >> "\$PASSWORD_FILE"
    echo "║  Conservala bene, ti servirà alla fine del viaggio!                           ║" >> "\$PASSWORD_FILE"
    echo "║                                                                               ║" >> "\$PASSWORD_FILE"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝" >> "\$PASSWORD_FILE"
    chmod 644 "\$PASSWORD_FILE"
    chown $REAL_USER:$REAL_USER "\$PASSWORD_FILE"

    # Scrive anche il log normale
    echo "" >> "\$LOG_FILE"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗" >> "\$LOG_FILE"
    echo "║                     🎯 PROCESSO FANTASMA TERMINATO!                           ║" >> "\$LOG_FILE"
    echo "╠═══════════════════════════════════════════════════════════════════════════════╣" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  Ottimo lavoro! Hai usato htop per trovare il processo e l'hai terminato!     ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  ═══════════════════════════════════════════════════════════════════════════  ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  ALTRI COMANDI UTILI PER GESTIRE I PROCESSI:                                  ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  • ps                → Processi della sessione corrente                       ║" >> "\$LOG_FILE"
    echo "║  • ps aux            → TUTTI i processi del sistema                           ║" >> "\$LOG_FILE"
    echo "║  • ps aux | grep X   → Filtra i processi cercando \"X\"                        ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  IL COMANDO KILL - Termina un processo:                                       ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  • kill <PID>        → Chiede gentilmente al processo di terminare (SIGTERM)  ║" >> "\$LOG_FILE"
    echo "║  • kill -9 <PID>     → Forza la terminazione immediata (SIGKILL)              ║" >> "\$LOG_FILE"
    echo "║  • killall <nome>    → Termina tutti i processi con quel nome                 ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  In htop puoi anche terminare processi direttamente con F9 (Kill)!            ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  ═══════════════════════════════════════════════════════════════════════════  ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  🎯 PROSSIMA SFIDA:                                                           ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "║  Vai in: /tmp/treasure_workspace/databank                                     ║" >> "\$LOG_FILE"
    echo "║                                                                               ║" >> "\$LOG_FILE"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝" >> "\$LOG_FILE"
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



# Crea un README per i processi in /tmp (file nascosto)
cat > "/tmp/.treasure_readme_processes.txt" << 'PROCESSREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 5                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  FILE NASCOSTI IN LINUX:                                                      ║
║  I file che iniziano con un punto (.) sono nascosti!                          ║
║  Per vederli serve: ls -la (la "a" sta per "all")                             ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  IL PACKAGE MANAGER APT: installa software su Linux!                          ║
║                                                                               ║
║  APT (Advanced Package Tool) è il gestore pacchetti di Debian/Ubuntu/Raspbian ║
║  Permette di installare, aggiornare e rimuovere programmi facilmente.         ║
║                                                                               ║
║  COMANDI PRINCIPALI:                                                          ║
║                                                                               ║
║  • sudo apt update           → Aggiorna la lista dei pacchetti disponibili    ║
║                                (da fare SEMPRE prima di installare!)          ║
║                                                                               ║
║  • sudo apt install <nome>   → Installa un programma                          ║
║    Esempio: sudo apt install htop                                             ║
║                                                                               ║
║  • sudo apt remove <nome>    → Rimuove un programma                           ║
║                                                                               ║
║  • sudo apt upgrade          → Aggiorna TUTTI i programmi installati          ║
║                                                                               ║
║  • apt search <parola>       → Cerca programmi per nome/descrizione           ║
║                                                                               ║
║  • apt show <nome>           → Mostra informazioni su un pacchetto            ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  HTOP - Monitor processi interattivo:                                         ║
║                                                                               ║
║  htop è una versione migliorata di "top", mostra i processi in tempo reale    ║
║  con un'interfaccia colorata e interattiva.                                   ║
║                                                                               ║
║  COMANDI IN HTOP:                                                             ║
║  • Frecce ↑↓     → Naviga tra i processi                                      ║
║  • F3 o /        → CERCA un processo per nome                                 ║
║  • F9            → Termina (kill) il processo selezionato                     ║
║  • F10 o q       → Esci da htop                                               ║
║  • F6            → Ordina per colonna                                         ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  Un processo misterioso chiamato "treasure_phantom_process" è in esecuzione!  ║
║                                                                               ║
║  1. Installa htop se non è presente:                                          ║
║     → sudo apt update                                                         ║
║     → sudo apt install htop -y                                                ║
║                                                                               ║
║  2. Avvia htop:                                                               ║
║     → htop                                                                    ║
║                                                                               ║
║  3. Cerca il processo "treasure_phantom" (usa F3 o /)                         ║
║                                                                               ║
║  4. Selezionalo e terminalo con F9, poi scegli SIGTERM (15)                   ║
║                                                                               ║
║  5. Esci da htop (q) e controlla cosa è apparso in /var/log/treasure/         ║
║     Il processo fantasma scrive un LOG quando viene terminato!                ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
PROCESSREADME

chmod 644 /tmp/.treasure_readme_processes.txt

print_progress "Tappa 5 configurata (Phantom PID: $PHANTOM_PID)"
#===============================================================================
# TAPPA 6: Grep e Pipe
#===============================================================================
print_step "Configurazione Tappa 6 - Grep..."

DATABANK_DIR="/tmp/treasure_workspace/databank"

create_decoy_files "$DATABANK_DIR" 120

# File "pagliaio" che contiene solo la parola chiave e il percorso dell'indizio 7
# Lo mettiamo in una cartella diversa così non trovano subito l'indizio con grep
mkdir -p /var/tmp/treasure_hidden

PAGLIAIO_FILE="$DATABANK_DIR/$(generate_filename)"
cat > "$PAGLIAIO_FILE" << 'PAGLIAIO'
pagliaio

Hai trovato l'ago! 🪡

Vai su: /var/tmp/treasure_hidden/
PAGLIAIO

# L'indizio 7 vero e proprio, in una cartella separata
cat > "/var/tmp/treasure_hidden/indizio7.txt" << 'INDIZIO7'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 7                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  🪡 AGO TROVATO NEL PAGLIAIO! Ottimo uso di grep!                             ║
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
INDIZIO7

cat > "$DATABANK_DIR/README_databank.txt" << 'GREPREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 6                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  GREP: Ricerca nei file                                                       ║
║                                                                               ║
║  Immagina di avere migliaia di file e dover trovare quello che contiene       ║
║  una parola specifica... impossibile farlo a mano!                            ║
║                                                                               ║
║  GREP è lo strumento perfetto: cerca testo dentro i file!                     ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  SINTASSI BASE:                                                               ║
║  • grep "pattern" file      → Cerca "pattern" nel file                        ║
║  • grep "pattern" *         → Cerca in tutti i file della directory           ║
║  • grep -r "pattern" .      → Cerca RICORSIVAMENTE in tutte le subdirectory   ║
║  • grep -l "pattern" *      → Mostra solo i NOMI dei file che contengono      ║
║  • grep -i "pattern" file   → Ricerca case-INSENSITIVE                        ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
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
║  In questa directory ci sono oltre 100 file...                                ║
║  è come cercare un ago in un pagilaio 🪡                                      ║
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

# Contenuto base per i file DECOY (senza indicazioni sulla prossima tappa)
DECOY_CONTENT='╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 9                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  ❌ Questo non è il file che cerchi...                                        ║
║                                                                               ║
║  L'"'"'hash non corrisponde! Continua a cercare.                                  ║
║                                                                               ║
║  Ricorda: ogni file ha un'"'"'impronta digitale unica.                            ║
║  Solo quello con l'"'"'hash giusto contiene le istruzioni!                        ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝'

# Genera 59 file DECOY
for i in $(seq 1 59); do
    DECOY_NAME=$(generate_filename)
    while [[ -f "$ARCHIVE_DIR/$DECOY_NAME" ]]; do
        DECOY_NAME=$(generate_filename)
    done
    echo "$DECOY_CONTENT" > "$ARCHIVE_DIR/$DECOY_NAME"
    # Aggiunge un numero finale per rendere ogni hash diverso
    echo "$i" >> "$ARCHIVE_DIR/$DECOY_NAME"
done

# IL FILE VERO - con le istruzioni complete per la prossima tappa
HASH_INDIZIO_FILE="$ARCHIVE_DIR/$(generate_filename)"
while [[ -f "$HASH_INDIZIO_FILE" ]]; do
    HASH_INDIZIO_FILE="$ARCHIVE_DIR/$(generate_filename)"
done

cat > "$HASH_INDIZIO_FILE" << 'HASHINDIZIO'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 9                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  ❌ Questo non è il file che cerchi...                                         ║
║  o forse si?                                                                  ║
║  Spostati in: /opt/treasure_hunt/backup                                       ║
║                                                                               ║
║  L'"'"'hash non corrisponde! Continua a cercare.                              ║
║                                                                               ║
║  Ricorda: ogni file ha un'"'"'impronta digitale unica.                        ║
║  Solo quello con l'"'"'hash giusto contiene le istruzioni!                    ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
HASHINDIZIO

TARGET_HASH=$(md5sum "$HASH_INDIZIO_FILE" | cut -d' ' -f1)

cat > "$ARCHIVE_DIR/README_archive.txt" << 'ARCHIVEREADME'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 8                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  GLI HASH: impronte digitali dei file!                                        ║
║                                                                               ║
║  Ogni file ha un HASH unico - una stringa di caratteri che lo identifica.     ║
║  Se anche un solo byte cambia, l'hash sarà completamente diverso!             ║
║                                                                               ║
║  Questo è utile per:                                                          ║
║  • Verificare che un download non sia corrotto                                ║
║  • Controllare se due file sono identici                                      ║
║  • Trovare un file specifico tra tanti                                        ║
║                                                                               ║
║  ═══════════════════════════════════════════════════════════════════════════  ║
║                                                                               ║
║  🎯 LA TUA MISSIONE:                                                          ║
║                                                                               ║
║  In questa cartella ci sono 60 file che SEMBRANO simili...                    ║
║  Ma uno solo ha l'hash che cerchi!                                            ║
║                                                                               ║
║  L'hash del file che contiene il prossimo indizio è in: target_hash.txt       ║
║                                                                               ║
║  Come trovarlo? Devi calcolare l'hash di ogni file e confrontare!             ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
ARCHIVEREADME

cat > "$ARCHIVE_DIR/target_hash.txt" << TARGETHASH
L'hash MD5 del file che cerchi è:

$TARGET_HASH

Trova il file con questo hash tra i tanti presenti in questa cartella!
TARGETHASH


print_progress "Tappa 8 configurata (Hash target: $TARGET_HASH)"

#===============================================================================
# TAPPA 9: Backup con ZIP finale
#===============================================================================
print_step "Configurazione Tappa 9 - Backup ZIP..."

BACKUP_DIR="/opt/treasure_hunt/backup"

# Copia il final_clue.zip
cp "$ASSETS_DIR/final_clue.zip" "$BACKUP_DIR/"

# Aggiungi qualche file decoy per non rendere troppo ovvio
create_decoy_files "$BACKUP_DIR" 20

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
