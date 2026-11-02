#!/usr/bin/env bash
# 03 — [PC x86_64] Empaqueta el kernel compilado (imagen, módulos, device trees)
#      y lo envía a la Raspberry Pi junto con mimodulo_arm64.ko y los scripts
#      que se ejecutan en la Pi.
#
# Uso:  ./scripts/03_pc_enviar_a_pi.sh
#       PI=usuario@ip ./scripts/03_pc_enviar_a_pi.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RPI_DIR="${RPI_DIR:-$HOME/rpi}"
PI="${PI:-valendipaolo@raspberrypi.local}"
KO_ARM="${KO_ARM:-$HOME/tp4-arm/mimodulo_arm64.ko}"

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

cd "$RPI_DIR/linux"
KREL="$(make -s kernelrelease)"

echo ">> Instalando módulos en un directorio temporal (../stage)"
rm -rf ../stage
make INSTALL_MOD_PATH=../stage INSTALL_MOD_STRIP=1 modules_install

echo ">> Empaquetando"
tar -C ../stage/lib/modules -czf "$RPI_DIR/modulos-tp4.tgz" "$KREL"
( cd arch/arm64/boot && tar -czf "$RPI_DIR/boot-tp4.tgz" \
    Image dts/broadcom/*.dtb dts/overlays/*.dtbo dts/overlays/README )
ls -lh "$RPI_DIR/modulos-tp4.tgz" "$RPI_DIR/boot-tp4.tgz" "$KO_ARM"

echo ">> Enviando a $PI"
scp "$RPI_DIR/modulos-tp4.tgz" "$RPI_DIR/boot-tp4.tgz" "$KO_ARM" \
    "$REPO_DIR/scripts/04_pi_instalar_kernel.sh" \
    "$REPO_DIR/scripts/05_pi_probar_modulo.sh" \
    "$PI":~
echo ">> Listo. En la Pi: bash ~/04_pi_instalar_kernel.sh"
