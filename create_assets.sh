
#!/bin/bash

#===============================================================================
#  🔧 CREA ASSETS - Da eseguire SOLO sulla macchina del professore
#  Genera i file ZIP e GPG da caricare nella repository
#===============================================================================

set -e

ASSETS_DIR="./assets"
mkdir -p "$ASSETS_DIR"

echo "🔧 Creazione assets per la repository..."

#-------------------------------------------------------------------------------
# 1. Crea i 5 archivi ZIP (solo 1 contiene l'indizio vero!)
#-------------------------------------------------------------------------------
echo "[1/2] Creazione archivi ZIP..."

# Array dei nomi degli archivi (sembrano tutti importanti!)
ARCHIVE_NAMES=(
    "backup_system_core"
    "data_dump_node7"
    "encrypted_payload"
    "kernel_snapshot_v2"
    "memory_sector_dump"
)

# L'archivio con l'indizio vero (randomico tra 0-4)
# Fissiamolo a 2 (encrypted_payload) per coerenza, ma puoi cambiarlo
CORRECT_ARCHIVE=2

for idx in "${!ARCHIVE_NAMES[@]}"; do
    ARCHIVE_NAME="${ARCHIVE_NAMES[$idx]}"
    ZIP_TEMP="/tmp/treasure_zip_build_${idx}_$$"
    mkdir -p "$ZIP_TEMP"
    
    if [[ $idx -eq $CORRECT_ARCHIVE ]]; then
        # ═══════════════════════════════════════════════════════════════
        # ARCHIVIO CORRETTO - Contiene l'indizio vero!
        # ═══════════════════════════════════════════════════════════════
        
        # Crea diverse sottocartelle per confondere
        mkdir -p "$ZIP_TEMP"/{logs,cache,data,config}
        
        # Riempi con file finti
        for i in $(seq 1 5); do
            echo "Log entry $i - System nominal, no anomalies detected." > "$ZIP_TEMP/logs/system_$i.log"
            echo "Cache block $i - Empty buffer" > "$ZIP_TEMP/cache/block_$i.dat"
            echo "Data sector $i - No readable content" > "$ZIP_TEMP/data/sector_$i.bin"
        done
        
        # IL FILE CON L'INDIZIO VERO (nascosto tra gli altri)
        cat > "$ZIP_TEMP/config/core_settings.cfg" << 'INDIZIO_VERO'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 8                         ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  🎉 HAI TROVATO L'ARCHIVIO GIUSTO!                                            ║
║                                                                               ║
║  Ora affronterai la sfida degli HASH!                                         ║
║                                                                               ║
║  Gli HASH sono "impronte digitali" dei file. Due file identici hanno          ║
║  lo stesso hash, file diversi hanno hash diversi (quasi sempre).              ║
║                                                                               ║
║  COMANDI:                                                                     ║
║  • md5sum file       → Calcola hash MD5                                       ║
║  • sha256sum file    → Calcola hash SHA256 (più sicuro)                       ║
║                                                                               ║
║  VAI IN: /opt/treasure_hunt/archive                                           ║
║                                                                               ║
║  Lì troverai un file "target_hash.txt" con l'hash da cercare, e molti         ║
║  altri file. Devi trovare quale file ha QUELL'HASH!                           ║
║                                                                               ║║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
INDIZIO_VERO
        
        # Aggiungi altri file config per mascherare
        echo "# Network configuration - default values" > "$ZIP_TEMP/config/network.cfg"
        echo "# Display settings - nothing here" > "$ZIP_TEMP/config/display.cfg"
        echo "# Audio config - silence" > "$ZIP_TEMP/config/audio.cfg"
        
    else
        # ═══════════════════════════════════════════════════════════════
        # ARCHIVI FALSI - Contengono messaggi di "sbagliato" divertenti
        # ═══════════════════════════════════════════════════════════════
        
        # Ogni archivio falso ha una struttura diversa per sembrare reale
        case $idx in
            0)  # backup_system_core
                mkdir -p "$ZIP_TEMP"/{system,boot,recovery}
                for i in $(seq 1 6); do
                    echo "System backup block $i - Corrupted data" > "$ZIP_TEMP/system/backup_$i.bak"
                done
                cat > "$ZIP_TEMP/recovery/restore_point.txt" << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              ❌ ARCHIVIO SBAGLIATO!                            ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   Questo backup di sistema non contiene l'indizio che cerchi...               ║
║                                                                               ║
║   "Questi non sono i droidi che state cercando." - Obi-Wan Kenobi             ║
║                                                                               ║
║   Prova con un altro archivio! 📦                                             ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
                echo "Boot sector - Nothing to see here" > "$ZIP_TEMP/boot/sector0.bin"
                ;;
                
            1)  # data_dump_node7
                mkdir -p "$ZIP_TEMP"/{node_data,packets,streams}
                for i in $(seq 1 8); do
                    echo "Packet capture $i - Empty transmission" > "$ZIP_TEMP/packets/capture_$i.pcap"
                done
                cat > "$ZIP_TEMP/node_data/analysis.txt" << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                              ❌ NOPE! SBAGLIATO!                               ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   Il Node 7 non ha mai contenuto informazioni utili...                        ║
║                                                                               ║
║   Fun fact: Il 7 è considerato un numero fortunato, ma non oggi!              ║
║                                                                               ║
║   Continua a cercare negli altri archivi! 🔍                                  ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
                echo "Stream buffer - Null bytes only" > "$ZIP_TEMP/streams/buffer.dat"
                ;;
                
            3)  # kernel_snapshot_v2
                mkdir -p "$ZIP_TEMP"/{modules,drivers,core}
                for i in $(seq 1 5); do
                    echo "Kernel module $i - Placeholder" > "$ZIP_TEMP/modules/mod_$i.ko"
                    echo "Driver binary $i - Stub" > "$ZIP_TEMP/drivers/drv_$i.sys"
                done
                cat > "$ZIP_TEMP/core/kernel_info.txt" << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                           ❌ KERNEL PANIC! (scherzo)                           ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   Questo snapshot del kernel non contiene l'indizio...                        ║
║                                                                               ║
║   Error 404: Treasure not found in this archive.                              ║
║                                                                               ║
║   Ma non mollare! Sei sulla strada giusta! 💪                                 ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
                ;;
                
            4)  # memory_sector_dump
                mkdir -p "$ZIP_TEMP"/{heap,stack,registers}
                for i in $(seq 1 7); do
                    echo "Memory dump sector $i - 0x00000000" > "$ZIP_TEMP/heap/sector_$i.mem"
                done
                cat > "$ZIP_TEMP/stack/trace.txt" << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                           ❌ SEGMENTATION FAULT!                               ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║   Core dumped... ma l'indizio non era qui!                                    ║
║                                                                               ║
║   "La memoria è fallace, come questo archivio." - Un programmatore saggio     ║
║                                                                               ║
║   Prova un altro file ZIP! 📂                                                 ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
                echo "Register state - All zeros" > "$ZIP_TEMP/registers/state.reg"
                ;;
        esac
    fi
    
    # Crea lo ZIP
    cd "$ZIP_TEMP"
    zip -r "$OLDPWD/$ASSETS_DIR/${ARCHIVE_NAME}.zip" . > /dev/null
    cd "$OLDPWD"
    rm -rf "$ZIP_TEMP"
    
    if [[ $idx -eq $CORRECT_ARCHIVE ]]; then
        echo "   ✅ ${ARCHIVE_NAME}.zip creato (⭐ QUESTO HA L'INDIZIO!)"
    else
        echo "   ✅ ${ARCHIVE_NAME}.zip creato (decoy)"
    fi
done

#-------------------------------------------------------------------------------
# 2. Crea il file ZIP con l'indizio finale
#-------------------------------------------------------------------------------
echo "[2/3] Creazione ZIP indizio finale..."

FINAL_CLUE_TEMP="/tmp/treasure_final_clue_$$"
mkdir -p "$FINAL_CLUE_TEMP"

cat > "$FINAL_CLUE_TEMP/indizio_finale.txt" << 'FINALCLUE'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                         🐧 MISSIONE LINUX - INDIZIO 10                        ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  🎉 SEI ARRIVATO ALL'ULTIMA TAPPA!                                            ║
║                                                                               ║
║  Il file finale criptato si trova in: /opt/treasure_hunt/final                ║
║                                                                               ║
║  Ma dove si trova la password?                                                ║
║                                                                               ║
║  La vita è un ciclo:                                                          ║
║  while(true) {                                                               ║
║       cerca_origine();                                                        ║
║   }                                                                           ║
║                                                                               ║║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
FINALCLUE

cd "$FINAL_CLUE_TEMP"
zip -r "$OLDPWD/$ASSETS_DIR/final_clue.zip" . > /dev/null
cd "$OLDPWD"
rm -rf "$FINAL_CLUE_TEMP"

echo "   ✅ final_clue.zip creato"

#-------------------------------------------------------------------------------
# 3. Crea il file GPG finale
#-------------------------------------------------------------------------------
echo "[3/3] Creazione file GPG criptato..."

FINAL_MESSAGE=$(cat << 'FINALE'


    ██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗
    ██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
    ██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝     ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝
    ██║     ██║██║╚██╗██║██║   ██║ ██╔██╗     ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗
    ███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║
    ╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝


╔═══════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                                   ║
║                            🏆 CONGRATULAZIONI! HAI COMPLETATO LA MISSIONE! 🏆                     ║
║                                                                                                   ║
╠═══════════════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                                   ║
║     Hai dimostrato di padroneggiare:                                                              ║
║                                                                                                   ║
║     ✅ Navigazione del filesystem Linux                                                           ║
║     ✅ Comandi base: cd, ls, cat, pwd                                                             ║
║     ✅ Concatenazione di file                                                                     ║
║     ✅ Wildcard e pattern matching                                                                ║
║     ✅ Il comando find                                                                            ║
║     ✅ Permessi dei file e chmod                                                                  ║
║     ✅ Gestione processi: ps, kill, htop                                                          ║
║     ✅ Grep e le pipe                                                                             ║
║     ✅ Gestione archivi compressi                                                                 ║
║     ✅ Hash e verifica integrità                                                                  ║
║     ✅ Crittografia con GPG                                                                       ║
║                                                                                                   ║
║  ═══════════════════════════════════════════════════════════════════════════════════════════════  ║
║                                                                                                   ║
║                                          🐧                                                       ║
║                                         ▄▄▄▄▄                                                     ║
║                                        ▐░░░░░▌                                                    ║
║                                       ▐░▄▄░▄▄░▌                                                   ║
║                                       ▐░▀░░░▀░▌                                                   ║
║                                        ▀▄░░░▄▀                                                    ║
║                                      ▄▄▄▀▀░▀▀▄▄▄                                                  ║
║                                     █░░░░░░░░░░░█                                                 ║
║                                     █░░░░░░░░░░░█                                                 ║
║                                      ▀▀▀▀▀▀▀▀▀▀▀                                                  ║
║                                                                                                   ║
║  ═══════════════════════════════════════════════════════════════════════════════════════════════  ║
║                                                                                                   ║
║     📢 VAI DAL PROFESSORE E PRONUNCIA LA FRASE:                                                   ║
║                                                                                                   ║
║                        "IO SONO UN VERO LINUX MASTER"                                             ║
║                                                                                                   ║
║                                                                                                   ║
║     🎮 Achievement Unlocked: Terminal Ninja 🥷                                                    ║
║                                                                                                   ║
╚═══════════════════════════════════════════════════════════════════════════════════════════════════╝


FINALE
)

echo "$FINAL_MESSAGE" | gpg --batch --yes --passphrase "I love TPSIT" \
    --symmetric --cipher-algo AES256 \
    -o "$ASSETS_DIR/final_mission.gpg" 2>/dev/null

echo "   ✅ final_mission.gpg creato (password: I love TPSIT)"

#-------------------------------------------------------------------------------
# Riepilogo
#-------------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "✅ ASSETS CREATI CON SUCCESSO!"
echo ""
echo "File generati in $ASSETS_DIR/:"
ls -la "$ASSETS_DIR"
echo ""
echo "📦 Archivi ZIP creati:"
echo "   • backup_system_core.zip     (decoy)"
echo "   • data_dump_node7.zip        (decoy)"
echo "   • encrypted_payload.zip      (⭐ INDIZIO VERO in config/core_settings.cfg)"
echo "   • kernel_snapshot_v2.zip     (decoy)"
echo "   • memory_sector_dump.zip     (decoy)"
echo "   • final_clue.zip             (⭐ Indizio finale per tappa 10)"
echo ""
echo "🔐 File GPG: final_mission.gpg (password: I love TPSIT)"
echo ""
echo "Ora puoi fare commit e push della repository!"
echo "═══════════════════════════════════════════════════════════════════"