#!/usr/bin/env bash
# 04 — [Raspberry Pi] Instala el kernel compilado en la PC y lo deja como
#      kernel de arranque (reversible). Ejecutar en la Pi, en el home.
#
# Para volver al kernel original: borrar la línea 'kernel=kernel-tp4.img'
# de /boot/firmware/config.txt y reiniciar.
#
# Uso:  bash ~/04_pi_instalar_kernel.sh
set -euo pipefail

BOOT=/boot/firmware
cd "$HOME"
[ -f modulos-tp4.tgz ] && [ -f boot-tp4.tgz ] || { echo "Faltan modulos-tp4.tgz / boot-tp4.tgz en $HOME"; exit 1; }

echo ">> Respaldo de $BOOT en ~/firmware-backup"
[ -d firmware-backup ] || sudo cp -a "$BOOT" firmware-backup

echo ">> Instalando módulos en /lib/modules"
sudo tar -C /lib/modules -xzf modulos-tp4.tgz
ls /lib/modules

echo ">> Instalando imagen del kernel y device trees"
mkdir -p boot-tp4
tar -C boot-tp4 -xzf boot-tp4.tgz
sudo cp boot-tp4/Image "$BOOT/kernel-tp4.img"
sudo cp boot-tp4/dts/broadcom/*.dtb "$BOOT/"
sudo cp boot-tp4/dts/overlays/*.dtbo boot-tp4/dts/overlays/README "$BOOT/overlays/"

if ! grep -q '^kernel=kernel-tp4.img' "$BOOT/config.txt"; then
    printf '\n[all]\nkernel=kernel-tp4.img\n' | sudo tee -a "$BOOT/config.txt" > /dev/null
fi
echo ">> Últimas líneas de config.txt:"
tail -3 "$BOOT/config.txt"

echo
echo ">> Listo. Reiniciá con 'sudo reboot' y verificá con 'uname -rm'."
