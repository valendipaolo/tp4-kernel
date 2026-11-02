#!/usr/bin/env bash
# 01 — [PC x86_64] Compilación cruzada del kernel de Raspberry Pi 5 (ARM64).
#
# Genera en $RPI_DIR/linux: arch/arm64/boot/Image, los módulos (.ko),
# los device trees (.dtb/.dtbo) y Module.symvers.
# Guarda en el repo el commit exacto usado (rpi-linux-commit.txt).
#
# Uso:  ./scripts/01_pc_compilar_kernel_rpi.sh
#       COMMIT=<hash> ./scripts/01_pc_compilar_kernel_rpi.sh   # reproducir un commit exacto
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RPI_DIR="${RPI_DIR:-$HOME/rpi}"
BRANCH="${BRANCH:-rpi-6.12.y}"
COMMIT="${COMMIT:-}"
LOCALVERSION_TP="-v8-16k-tp4"

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

echo ">> Instalando compilador cruzado y dependencias"
sudo apt install -y git bc bison flex libssl-dev libncurses-dev make crossbuild-essential-arm64

echo ">> Descargando la fuente del kernel de Raspberry Pi (rama $BRANCH)"
mkdir -p "$RPI_DIR"
cd "$RPI_DIR"
if [ ! -d linux ]; then
    git clone --depth=1 --branch "$BRANCH" https://github.com/raspberrypi/linux
fi
cd linux
if [ -n "$COMMIT" ]; then
    git fetch --depth=1 origin "$COMMIT"
    git checkout "$COMMIT"
fi

echo ">> Configurando para Raspberry Pi 5 (BCM2712, páginas de 16K)"
make bcm2712_defconfig
./scripts/config --set-str LOCALVERSION "$LOCALVERSION_TP"
make olddefconfig

echo ">> Compilando kernel + módulos + device trees (puede tardar ~30 min)"
make -j"$(nproc)" Image modules dtbs

git log -1 --format='%H %cd' > "$REPO_DIR/rpi-linux-commit.txt"

echo
echo "== Resultado =="
echo "kernelrelease:  $(make -s kernelrelease)"
ls -lh arch/arm64/boot/Image Module.symvers
echo "módulos .ko:    $(find . -name '*.ko' | wc -l) de $(wc -l < modules.order)"
echo "commit fuente:  $(cat "$REPO_DIR/rpi-linux-commit.txt")"
