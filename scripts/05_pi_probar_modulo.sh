#!/usr/bin/env bash
# 05 — [Raspberry Pi] Carga y descarga mimodulo_arm64.ko (se espera que FUNCIONE).
#      Ejecutar en la Pi después de reiniciar con el kernel nuevo (script 04).
#
# Uso:  bash ~/05_pi_probar_modulo.sh
set -euo pipefail

KO="${KO:-$HOME/mimodulo_arm64.ko}"

echo "== Kernel en ejecución =="
uname -rm
echo
echo "== Módulo a cargar =="
ls -lh "$KO"
echo
echo "== Carga =="
sudo insmod "$KO"
sudo dmesg | tail -3
lsmod | grep mimodulo
sudo grep mimodulo /proc/modules
echo
echo "== Descarga =="
sudo rmmod mimodulo
sudo dmesg | tail -1
