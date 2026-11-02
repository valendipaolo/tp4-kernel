#!/usr/bin/env bash
# 02 — [PC x86_64] Compilación cruzada de mimodulo para ARM64 e intento de
#      carga en la PC (se espera que FALLE).
#
# Requiere haber corrido 01 (necesita $RPI_DIR/linux con Module.symvers).
# Deja el módulo para ARM en $OUT_DIR/mimodulo_arm64.ko.
#
# Uso:  ./scripts/02_pc_crosscompilar_modulo.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RPI_DIR="${RPI_DIR:-$HOME/rpi}"
MOD_DIR="${MOD_DIR:-$REPO_DIR/part1/module}"
OUT_DIR="${OUT_DIR:-$HOME/tp4-arm}"
KO_ARM="$OUT_DIR/mimodulo_arm64.ko"

# ARCH y CROSS_COMPILE se pasan explícitamente SOLO a la compilación cruzada:
# si quedaran exportados, los 'make' nativos de la PC también los usarían.
unset ARCH CROSS_COMPILE

[ -f "$RPI_DIR/linux/Module.symvers" ] || { echo "Falta $RPI_DIR/linux/Module.symvers: corré primero 01_pc_compilar_kernel_rpi.sh"; exit 1; }

cd "$MOD_DIR"
echo ">> Compilación cruzada de mimodulo contra el kernel de la Pi"
make clean
make -C "$RPI_DIR/linux" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- M="$PWD" modules

mkdir -p "$OUT_DIR"
cp mimodulo.ko "$KO_ARM"

echo
echo "== Verificación del binario =="
file "$KO_ARM"
modinfo "$KO_ARM" | grep vermagic
modprobe --dump-modversions "$KO_ARM" | grep -E '_printk|module_layout'

echo
echo "== Intento de carga en la PC ($(uname -m)) — se espera que falle =="
if sudo insmod "$KO_ARM"; then
    echo "INESPERADO: el módulo ARM cargó en la PC"
    sudo rmmod mimodulo
    exit 1
else
    echo "OK: la PC rechazó el módulo"
fi
sudo dmesg | tail -1

echo
echo ">> Restaurando la versión nativa (x86_64) de mimodulo en $MOD_DIR"
make clean
make
