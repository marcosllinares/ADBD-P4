#!/bin/bash

DB="viveros"

# Lista de las 11 tablas del modelo relacional + vista analítica
TABLAS=(
  "vivero"
  "zona"
  "producto"
  "stock_zona"
  "empleado"
  "historico_empleado_zona"
  "cliente"
  "cliente_plus"
  "bonificacion"
  "pedido"
  "detalle_pedido"
  "vista_calculo_bonificaciones_mensuales"
)

echo "================================================================================"
echo "         SALIDAS DE LOS SELECT DE CADA TABLA (BASE DE DATOS: Viveros)"
echo ""

for tabla in "${TABLAS[@]}"; do
  echo "================================================================================"
  echo " >>> TABLA: $tabla"
  echo "================================================================================"
  psql -d "$DB" -c "SELECT * FROM \"$tabla\";"
  echo ""
done
