#!/bin/bash
# ============================================================================
# Práctica 4: Salidas formateadas de los SELECT de todas las tablas
# Base de datos: viveros
# Asignatura: Administración y Diseño de Bases de Datos (ADBD) - ULL
# ============================================================================

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
echo "         SALIDAS DE LOS SELECT DE CADA TABLA (BASE DE DATOS: $DB)"
echo "================================================================================"
echo ""

for tabla in "${TABLAS[@]}"; do
  echo "================================================================================"
  echo " >>> TABLA: $tabla"
  echo "================================================================================"
  psql -d "$DB" -c "SELECT * FROM \"$tabla\";"
  echo ""
done
