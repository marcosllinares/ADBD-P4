-- ============================================================================
-- PRÁCTICA 4: MODELO RELACIONAL Y POSTGRESQL - TAJINASTE S.A. (VIVEROS)
-- Asignatura: Administración y Diseño de Bases de Datos (ADBD)
-- Grado en Ingeniería Informática - Universidad de La Laguna (ULL)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ----------------------------------------------------------------------------
DROP DATABASE IF EXISTS viveros;
CREATE DATABASE viveros;
\c viveros;

-- ----------------------------------------------------------------------------
-- 2. DEFINICIÓN DE TABLAS CON RESTRICCIONES CHECK, NOT NULL Y CLAVES
-- ----------------------------------------------------------------------------

-- 2.1. VIVERO
CREATE TABLE "vivero" (
  "id_vivero" int PRIMARY KEY,
  "nombre" varchar(100) NOT NULL,
  "latitud" decimal(9,6) NOT NULL,
  "longitud" decimal(9,6) NOT NULL,
  "direccion" varchar(200) NOT NULL,
  CONSTRAINT chk_vivero_latitud CHECK ("latitud" BETWEEN -90.0 AND 90.0),
  CONSTRAINT chk_vivero_longitud CHECK ("longitud" BETWEEN -180.0 AND 180.0)
);

COMMENT ON TABLE "vivero" IS 'Instalaciones físicas independientes donde opera Tajinaste S.A.';
COMMENT ON COLUMN "vivero"."id_vivero" IS 'Identificador unívoco del vivero';
COMMENT ON COLUMN "vivero"."latitud" IS 'Coordenada WGS84 [-90.0, 90.0]';
COMMENT ON COLUMN "vivero"."longitud" IS 'Coordenada WGS84 [-180.0, 180.0]';

-- 2.2. ZONA
CREATE TABLE "zona" (
  "id_zona" int PRIMARY KEY,
  "id_vivero" int NOT NULL,
  "nombre" varchar(50) NOT NULL,
  "latitud" decimal(9,6) NOT NULL,
  "longitud" decimal(9,6) NOT NULL,
  CONSTRAINT chk_zona_latitud CHECK ("latitud" BETWEEN -90.0 AND 90.0),
  CONSTRAINT chk_zona_longitud CHECK ("longitud" BETWEEN -180.0 AND 180.0)
);

COMMENT ON TABLE "zona" IS 'Subdivisiones operativas de un vivero con georreferenciación propia';
COMMENT ON COLUMN "zona"."id_zona" IS 'Identificador único de la zona';
COMMENT ON COLUMN "zona"."id_vivero" IS 'Vivero al que pertenece la zona (1:N)';
COMMENT ON COLUMN "zona"."nombre" IS 'Exterior, Almacén, Invernadero, etc.';

-- 2.3. PRODUCTO
CREATE TABLE "producto" (
  "id_producto" varchar(15) PRIMARY KEY,
  "nombre" varchar(100) NOT NULL,
  "tipo" varchar(30) NOT NULL,
  "precio_unitario" decimal(8,2) NOT NULL,
  "descripcion" text,
  CONSTRAINT chk_producto_precio CHECK ("precio_unitario" >= 0.00),
  CONSTRAINT chk_producto_tipo CHECK ("tipo" IN ('Planta', 'Jardinería', 'Decoración'))
);

COMMENT ON TABLE "producto" IS 'Bienes comercializados en la red de viveros';
COMMENT ON COLUMN "producto"."id_producto" IS 'Código de catálogo del producto';
COMMENT ON COLUMN "producto"."tipo" IS 'Planta, Jardinería, Decoración';
COMMENT ON COLUMN "producto"."precio_unitario" IS 'Precio base >= 0.00';

-- 2.4. STOCK_ZONA (Relación M:N almacena)
CREATE TABLE "stock_zona" (
  "id_zona" int NOT NULL,
  "id_producto" varchar(15) NOT NULL,
  "cantidad_disponible" int NOT NULL DEFAULT 0,
  PRIMARY KEY ("id_zona", "id_producto"),
  CONSTRAINT chk_stock_cantidad CHECK ("cantidad_disponible" >= 0)
);

COMMENT ON TABLE "stock_zona" IS 'Relación M:N almacena entre Zona y Producto';
COMMENT ON COLUMN "stock_zona"."cantidad_disponible" IS 'Unidades en stock >= 0';

-- 2.5. EMPLEADO
CREATE TABLE "empleado" (
  "dni" varchar(9) PRIMARY KEY,
  "num_seguridad_social" varchar(12) UNIQUE NOT NULL,
  "nombre" varchar(50) NOT NULL,
  "apellidos" varchar(100) NOT NULL,
  "telefono" varchar(15) NOT NULL,
  "email" varchar(100) UNIQUE NOT NULL
);

COMMENT ON TABLE "empleado" IS 'Plantilla de trabajadores de la empresa';
COMMENT ON COLUMN "empleado"."dni" IS 'NIF/NIE del empleado';

-- 2.6. HISTORICO_EMPLEADO_ZONA (Relación M:N histórica trabaja en)
CREATE TABLE "historico_empleado_zona" (
  "dni_empleado" varchar(9) NOT NULL,
  "id_zona" int NOT NULL,
  "fecha_inicio" date NOT NULL,
  "fecha_fin" date,
  "tarea" varchar(100) NOT NULL,
  PRIMARY KEY ("dni_empleado", "id_zona", "fecha_inicio"),
  CONSTRAINT chk_historico_fechas CHECK ("fecha_fin" IS NULL OR "fecha_fin" >= "fecha_inicio")
);

COMMENT ON TABLE "historico_empleado_zona" IS 'Relación M:N histórica trabaja en entre Empleado y Zona';
COMMENT ON COLUMN "historico_empleado_zona"."fecha_inicio" IS 'Inicio del destino temporal';
COMMENT ON COLUMN "historico_empleado_zona"."fecha_fin" IS 'NULL si es el puesto activo actual';
COMMENT ON COLUMN "historico_empleado_zona"."tarea" IS 'Función asignada (riego, almacén, venta, etc.)';

-- 2.7. CLIENTE (Superclase)
CREATE TABLE "cliente" (
  "dni" varchar(9) PRIMARY KEY,
  "nombre" varchar(50) NOT NULL,
  "apellidos" varchar(100) NOT NULL,
  "telefono" varchar(15) NOT NULL,
  "email" varchar(100) UNIQUE NOT NULL
);

COMMENT ON TABLE "cliente" IS 'Superclase: Clientes generales registrados';
COMMENT ON COLUMN "cliente"."dni" IS 'NIF/NIE del cliente';

-- 2.8. CLIENTE_PLUS (Subclase especializada 1:1)
CREATE TABLE "cliente_plus" (
  "dni" varchar(9) PRIMARY KEY,
  "codigo_plus" varchar(20) UNIQUE NOT NULL,
  "fecha_ingreso" date NOT NULL
);

COMMENT ON TABLE "cliente_plus" IS 'Subclase especializada para socios del programa Tajinaste Plus';
COMMENT ON COLUMN "cliente_plus"."dni" IS 'Hereda la PK de cliente (relación 1:1)';
COMMENT ON COLUMN "cliente_plus"."codigo_plus" IS 'Número de tarjeta de socio';
COMMENT ON COLUMN "cliente_plus"."fecha_ingreso" IS 'Fecha de adhesión al programa de fidelización';

-- 2.9. BONIFICACION (Entidad débil de Cliente Plus)
CREATE TABLE "bonificacion" (
  "id_bonificacion" INT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  "dni_cliente_plus" varchar(9) NOT NULL,
  "mes" int NOT NULL,
  "anio" int NOT NULL,
  "volumen_compras" decimal(10,2) NOT NULL DEFAULT 0.00,
  "importe_bonificado" decimal(8,2) NOT NULL DEFAULT 0.00,
  CONSTRAINT chk_bonificacion_mes CHECK ("mes" BETWEEN 1 AND 12),
  CONSTRAINT chk_bonificacion_anio CHECK ("anio" >= 2000),
  CONSTRAINT chk_bonificacion_volumen CHECK ("volumen_compras" >= 0.00),
  CONSTRAINT chk_bonificacion_importe CHECK ("importe_bonificado" >= 0.00)
);

CREATE UNIQUE INDEX ON "bonificacion" ("dni_cliente_plus", "mes", "anio");
COMMENT ON TABLE "bonificacion" IS 'Entidad débil dependiente de Cliente Plus para acumular recompensas mensuales';

-- 2.10. PEDIDO
CREATE TABLE "pedido" (
  "id_pedido" int PRIMARY KEY,
  "dni_cliente_plus" varchar(9) NOT NULL,
  "dni_empleado_responsable" varchar(9) NOT NULL,
  "fecha" timestamp NOT NULL DEFAULT (now()),
  "importe_total" decimal(10,2) NOT NULL DEFAULT 0.00,
  "estado" varchar(20) NOT NULL DEFAULT 'Pendiente',
  CONSTRAINT chk_pedido_importe CHECK ("importe_total" >= 0.00),
  CONSTRAINT chk_pedido_estado CHECK ("estado" IN ('Pendiente', 'Completado', 'Cancelado'))
);

COMMENT ON TABLE "pedido" IS 'Pedidos realizados por socios Tajinaste Plus y gestionados por empleados';
COMMENT ON COLUMN "pedido"."importe_total" IS 'Atributo derivado calculado automáticamente desde detalle_pedido';
COMMENT ON COLUMN "pedido"."estado" IS 'Pendiente, Completado, Cancelado';

-- 2.11. DETALLE_PEDIDO (Relación M:N contiene)
CREATE TABLE "detalle_pedido" (
  "id_pedido" int NOT NULL,
  "id_producto" varchar(15) NOT NULL,
  "cantidad" int NOT NULL,
  "precio_unitario_aplicado" decimal(8,2) NOT NULL,
  PRIMARY KEY ("id_pedido", "id_producto"),
  CONSTRAINT chk_detalle_cantidad CHECK ("cantidad" > 0),
  CONSTRAINT chk_detalle_precio CHECK ("precio_unitario_aplicado" >= 0.00)
);

COMMENT ON TABLE "detalle_pedido" IS 'Relación M:N contiene entre Pedido y Producto';
COMMENT ON COLUMN "detalle_pedido"."cantidad" IS 'Unidades compradas > 0';
COMMENT ON COLUMN "detalle_pedido"."precio_unitario_aplicado" IS 'Precio histórico al momento de la venta';

-- ----------------------------------------------------------------------------
-- 3. INTEGRIDAD REFERENCIAL (CLAVES FORÁNEAS)
-- ----------------------------------------------------------------------------

-- Zona pertenece a Vivero (Restringe borrado si hay zonas)
ALTER TABLE "zona" 
  ADD CONSTRAINT fk_zona_vivero 
  FOREIGN KEY ("id_vivero") REFERENCES "vivero" ("id_vivero") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- Stock en zona (Cascada si desaparece la zona, Restrict si el producto existe)
ALTER TABLE "stock_zona" 
  ADD CONSTRAINT fk_stock_zona 
  FOREIGN KEY ("id_zona") REFERENCES "zona" ("id_zona") 
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "stock_zona" 
  ADD CONSTRAINT fk_stock_producto 
  FOREIGN KEY ("id_producto") REFERENCES "producto" ("id_producto") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- Histórico de destinos
ALTER TABLE "historico_empleado_zona" 
  ADD CONSTRAINT fk_historico_empleado 
  FOREIGN KEY ("dni_empleado") REFERENCES "empleado" ("dni") 
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "historico_empleado_zona" 
  ADD CONSTRAINT fk_historico_zona 
  FOREIGN KEY ("id_zona") REFERENCES "zona" ("id_zona") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- Jerarquía de herencia 1:1 (Borrado en cascada del socio si se elimina el cliente)
ALTER TABLE "cliente_plus" 
  ADD CONSTRAINT fk_cliente_plus_cliente 
  FOREIGN KEY ("dni") REFERENCES "cliente" ("dni") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Bonificación (Entidad débil: se borran sus bonificaciones si se elimina el cliente Plus)
ALTER TABLE "bonificacion" 
  ADD CONSTRAINT fk_bonificacion_cliente 
  FOREIGN KEY ("dni_cliente_plus") REFERENCES "cliente_plus" ("dni") 
  ON DELETE CASCADE ON UPDATE CASCADE;

-- Pedidos vinculados a Cliente Plus y Empleado responsable
ALTER TABLE "pedido" 
  ADD CONSTRAINT fk_pedido_cliente 
  FOREIGN KEY ("dni_cliente_plus") REFERENCES "cliente_plus" ("dni") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "pedido" 
  ADD CONSTRAINT fk_pedido_empleado 
  FOREIGN KEY ("dni_empleado_responsable") REFERENCES "empleado" ("dni") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- Detalle de Pedido (Borrado en cascada de líneas al borrar el pedido)
ALTER TABLE "detalle_pedido" 
  ADD CONSTRAINT fk_detalle_pedido 
  FOREIGN KEY ("id_pedido") REFERENCES "pedido" ("id_pedido") 
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "detalle_pedido" 
  ADD CONSTRAINT fk_detalle_producto 
  FOREIGN KEY ("id_producto") REFERENCES "producto" ("id_producto") 
  ON DELETE RESTRICT ON UPDATE CASCADE;

-- ----------------------------------------------------------------------------
-- 4. ATRIBUTOS DERIVADOS (CALCULADOS) - TRIGGERS Y FUNCIONES EN POSTGRESQL
-- ----------------------------------------------------------------------------

-- Función y Trigger para calcular y mantener automáticamente el importe_total en PEDIDO
CREATE OR REPLACE FUNCTION fn_actualizar_importe_pedido()
RETURNS TRIGGER AS $$
DECLARE
  v_id_pedido INT;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    v_id_pedido := OLD.id_pedido;
  ELSE
    v_id_pedido := NEW.id_pedido;
  END IF;

  UPDATE pedido
  SET importe_total = COALESCE((
    SELECT SUM(cantidad * precio_unitario_aplicado)
    FROM detalle_pedido
    WHERE id_pedido = v_id_pedido
  ), 0.00)
  WHERE id_pedido = v_id_pedido;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_importe_pedido
AFTER INSERT OR UPDATE OR DELETE ON detalle_pedido
FOR EACH ROW
EXECUTE FUNCTION fn_actualizar_importe_pedido();

-- Vista analítica de apoyo para el cálculo dinámico de bonificaciones por volumen mensual
CREATE OR REPLACE VIEW vista_calculo_bonificaciones_mensuales AS
SELECT 
  p.dni_cliente_plus,
  EXTRACT(MONTH FROM p.fecha)::INT AS mes,
  EXTRACT(YEAR FROM p.fecha)::INT AS anio,
  SUM(p.importe_total) AS volumen_compras_real,
  ROUND(SUM(p.importe_total) * 0.05, 2) AS bonificacion_5_porciento
FROM pedido p
WHERE p.estado = 'Completado'
GROUP BY p.dni_cliente_plus, EXTRACT(MONTH FROM p.fecha), EXTRACT(YEAR FROM p.fecha);

-- ----------------------------------------------------------------------------
-- 5. POBLACIÓN DE DATOS (AL MENOS 5 FILAS POR TABLA - TODOS LOS ESCENARIOS)
-- ----------------------------------------------------------------------------

BEGIN;

INSERT INTO "vivero" ("id_vivero", "nombre", "latitud", "longitud", "direccion") VALUES
  (1, 'Vivero Tacoronte Norte', 28.481234, -16.415678, 'Carretera General del Norte, km 15, Tacoronte'),
  (2, 'Vivero Valle de La Orotava', 28.391100, -16.523400, 'Camino El Bosque 12, La Orotava'),
  (3, 'Vivero Costa Adeje', 28.125600, -16.732100, 'Avenida de los Viveros 4, Adeje'),
  (4, 'Vivero Candelaria Sur', 28.354100, -16.371200, 'Calle Las Caletillas 8, Candelaria'),
  (5, 'Vivero San Cristóbal', 28.487600, -16.315400, 'Camino San Lázaro 45, La Laguna');

INSERT INTO "zona" ("id_zona", "id_vivero", "nombre", "latitud", "longitud") VALUES
  (101, 1, 'Zona Exterior Plantas Autóctonas', 28.481300, -16.415710),
  (102, 1, 'Almacén Central Tacoronte', 28.481210, -16.415650),
  (201, 2, 'Invernadero Climatizado Flores', 28.391150, -16.523450),
  (301, 3, 'Exposición Plantas Tropicales', 28.125650, -16.732150),
  (401, 4, 'Zona Venta y Decoración Exterior', 28.354150, -16.371250),
  (501, 5, 'Almacén de Herramientas y Sustratos', 28.487650, -16.315450);

INSERT INTO "producto" ("id_producto", "nombre", "tipo", "precio_unitario", "descripcion") VALUES
  ('PRD-PLANT-01', 'Drago Canario (Dracaena draco)', 'Planta', 28.50, 'Ejemplar joven en maceta de 25 cm, especie autóctona'),
  ('PRD-PLANT-02', 'Palmera Canaria (Phoenix canariensis)', 'Planta', 45.00, 'Palmera canaria de 1 metro de altura, adaptada a exterior'),
  ('PRD-JARD-01', 'Tijeras de Podar Ergonómicas Pro', 'Jardinería', 18.75, 'Tijeras de acero inoxidable con mango antideslizante'),
  ('PRD-JARD-02', 'Sustrato Universal Volcánico 50L', 'Jardinería', 9.20, 'Sustrato enriquecido con picón volcánico y materia orgánica'),
  ('PRD-DECO-01', 'Maceta Artesanal de Barro 40cm', 'Decoración', 22.00, 'Maceta de barro cocido hecha a mano, resistente a intemperie'),
  ('PRD-DECO-02', 'Farol Solar LED de Jardín', 'Decoración', 14.50, 'Luminaria solar estanca para caminos y zonas exteriores');

INSERT INTO "stock_zona" ("id_zona", "id_producto", "cantidad_disponible") VALUES
  (101, 'PRD-PLANT-01', 35),
  (101, 'PRD-PLANT-02', 15),
  (102, 'PRD-JARD-02', 120),
  (201, 'PRD-PLANT-01', 20),
  (301, 'PRD-DECO-01', 40),
  (401, 'PRD-DECO-02', 60),
  (501, 'PRD-JARD-01', 85);

INSERT INTO "empleado" ("dni", "num_seguridad_social", "nombre", "apellidos", "telefono", "email") VALUES
  ('42345678Z', '381234567890', 'Laura', 'García Ramos', '+34600123456', 'lgarcia@tajinaste.com'),
  ('43876543Y', '381234567891', 'Alejandro', 'Hernández Pérez', '+34611234567', 'ahernandez@tajinaste.com'),
  ('78901234X', '381234567892', 'Marta', 'González Dorta', '+34622345678', 'mgonzalez@tajinaste.com'),
  ('54123987W', '381234567893', 'Carlos', 'Mendoza Afonso', '+34633456789', 'cmendoza@tajinaste.com'),
  ('45678912V', '381234567894', 'Elena', 'Brito Cabrera', '+34644567890', 'ebrito@tajinaste.com');

INSERT INTO "historico_empleado_zona" ("dni_empleado", "id_zona", "fecha_inicio", "fecha_fin", "tarea") VALUES
  ('42345678Z', 101, '2023-01-10', '2023-06-30', 'Encargada de riego y aclimatación de planta autóctona'),
  ('42345678Z', 102, '2023-07-01', NULL, 'Gestión de logística y stock en almacén central'),
  ('43876543Y', 201, '2023-03-15', NULL, 'Control de clima y floración en invernadero'),
  ('78901234X', 301, '2023-02-01', '2023-12-31', 'Asesoramiento técnico y venta directa de tropicales'),
  ('78901234X', 401, '2024-01-01', NULL, 'Atención comercial y asesoría en decoración'),
  ('54123987W', 501, '2023-05-01', NULL, 'Recepción de mercancías y preparación de pedidos'),
  ('45678912V', 101, '2023-09-01', NULL, 'Mantenimiento de zonas exteriores y poda de temporada');

INSERT INTO "cliente" ("dni", "nombre", "apellidos", "telefono", "email") VALUES
  ('78912345T', 'Carlos', 'Martín Pérez', '+34677987654', 'cmartin@gmail.com'),
  ('43567890R', 'Beatriz', 'López Santana', '+34688112233', 'blopez@hotmail.com'),
  ('54231987P', 'Diego', 'Navarro Curbelo', '+34699445566', 'dnavarro@yahoo.es'),
  ('78654321M', 'Silvia', 'Rodríguez Mesa', '+34670223344', 'srodriguez@gmail.com'),
  ('42112233K', 'Javier', 'Domínguez León', '+34680334455', 'jdominguez@outlook.com'),
  ('55667788S', 'Patricia', 'Herrera Vega', '+34690445566', 'pherrera@gmail.com');

INSERT INTO "cliente_plus" ("dni", "codigo_plus", "fecha_ingreso") VALUES
  ('78912345T', 'PLS-2023-001', '2023-02-15'),
  ('43567890R', 'PLS-2023-045', '2023-04-10'),
  ('54231987P', 'PLS-2023-112', '2023-07-01'),
  ('78654321M', 'PLS-2024-019', '2024-01-20'),
  ('42112233K', 'PLS-2024-088', '2024-03-05');

INSERT INTO "bonificacion" ("dni_cliente_plus", "mes", "anio", "volumen_compras", "importe_bonificado") VALUES
  ('78912345T', 3, 2024, 345.50, 17.28),
  ('78912345T', 4, 2024, 520.00, 26.00),
  ('43567890R', 3, 2024, 185.00, 9.25),
  ('54231987P', 4, 2024, 410.20, 20.51),
  ('78654321M', 4, 2024, 98.00, 4.90);

-- Se insertan los pedidos con importe_total inicial a 0.00 (el Trigger lo calculará)
INSERT INTO "pedido" ("id_pedido", "dni_cliente_plus", "dni_empleado_responsable", "fecha", "estado") VALUES
  (1001, '78912345T', '42345678Z', '2024-03-10 10:30:00', 'Completado'),
  (1002, '43567890R', '78901234X', '2024-03-18 12:15:00', 'Completado'),
  (1003, '78912345T', '42345678Z', '2024-04-05 16:45:00', 'Completado'),
  (1004, '54231987P', '43876543Y', '2024-04-12 11:20:00', 'Pendiente'),
  (1005, '42112233K', '78901234X', '2024-04-20 09:50:00', 'Cancelado'),
  (1006, '78654321M', '42345678Z', '2024-04-22 17:10:00', 'Completado');

-- Al insertar los detalles de pedido, se dispara el Trigger y calcula importe_total automáticamente
INSERT INTO "detalle_pedido" ("id_pedido", "id_producto", "cantidad", "precio_unitario_aplicado") VALUES
  (1001, 'PRD-PLANT-01', 2, 28.50),
  (1001, 'PRD-DECO-01', 2, 22.50),
  (1002, 'PRD-JARD-01', 2, 18.75),
  (1002, 'PRD-DECO-01', 2, 26.00),
  (1003, 'PRD-PLANT-02', 3, 45.00),
  (1004, 'PRD-PLANT-02', 1, 45.00),
  (1005, 'PRD-JARD-01', 1, 18.75),
  (1005, 'PRD-DECO-01', 1, 22.00),
  (1005, 'PRD-JARD-02', 2, 9.00),
  (1006, 'PRD-PLANT-01', 2, 28.50),
  (1006, 'PRD-DECO-02', 2, 14.50),
  (1006, 'PRD-JARD-02', 1, 12.00);

COMMIT;

-- ----------------------------------------------------------------------------
-- 6. EJEMPLOS REPRESENTATIVOS DE OPERACIONES DELETE (REQUERIDO POR EL ENUNCIADO)
-- ----------------------------------------------------------------------------

-- ============================================================================
-- EJEMPLO 1: DEMOSTRACIÓN DE BORRADO EN CASCADA (ON DELETE CASCADE)
-- Escenario: Insertamos un pedido temporal de prueba (id_pedido = 9999) con
-- sus líneas de detalle. Al eliminar el pedido, sus líneas en 'detalle_pedido'
-- se eliminan automáticamente sin dejar huérfanos, preservando intactos
-- todos los pedidos originales del catálogo (1001 a 1006).
-- ============================================================================
INSERT INTO "pedido" ("id_pedido", "dni_cliente_plus", "dni_empleado_responsable", "fecha", "estado")
VALUES (9999, '78912345T', '42345678Z', '2024-05-01 10:00:00', 'Pendiente');

INSERT INTO "detalle_pedido" ("id_pedido", "id_producto", "cantidad", "precio_unitario_aplicado")
VALUES 
  (9999, 'PRD-PLANT-01', 1, 28.50),
  (9999, 'PRD-DECO-01', 1, 22.00);

-- Ejecución del borrado en cascada del pedido temporal:
DELETE FROM pedido WHERE id_pedido = 9999;

-- Comprobación (ambas consultas devuelven 0 filas confirmando el borrado en cascada):
-- SELECT * FROM pedido WHERE id_pedido = 9999;
-- SELECT * FROM detalle_pedido WHERE id_pedido = 9999;


-- ============================================================================
-- EJEMPLO 2: DEMOSTRACIÓN DE INTEGRIDAD RESTRICTIVA (ON DELETE RESTRICT)
-- Escenario: Intentar eliminar un vivero que posee zonas operativas asociadas.
-- Resultado esperado: PostgreSQL debe ABORTAR la operación con un error
-- 'violates foreign key constraint fk_zona_vivero on table zona'.
-- ============================================================================
-- Descomentar la siguiente línea para comprobar el bloqueo por restricción:
-- DELETE FROM vivero WHERE id_vivero = 1;


-- ============================================================================
-- EJEMPLO 3: DEMOSTRACIÓN DE BORRADO EN JERARQUÍA Y ENTIDAD DÉBIL (CASCADE)
-- Escenario: Si un cliente general se da de baja, se eliminan en cascada
-- su condición de socio en 'cliente_plus' y sus registros en 'bonificacion'.
-- Primero insertamos un cliente de prueba con bonificación para poder borrarlo
-- sin violar la restricción RESTRICT de pedidos existentes:
-- ============================================================================
INSERT INTO cliente (dni, nombre, apellidos, telefono, email)
VALUES ('99999999K', 'Cliente', 'Temporal Borrado', '+34699999999', 'temp@tajinaste.com');

INSERT INTO cliente_plus (dni, codigo_plus, fecha_ingreso)
VALUES ('99999999K', 'PLS-TEMP-99', '2024-01-01');

INSERT INTO bonificacion (dni_cliente_plus, mes, anio, volumen_compras, importe_bonificado)
VALUES ('99999999K', 1, 2024, 100.00, 5.00);

-- Ejecución del borrado en cascada:
DELETE FROM cliente WHERE dni = '99999999K';

-- Comprobación (ambas deben devolver 0 filas):
-- SELECT * FROM cliente_plus WHERE dni = '99999999K';
-- SELECT * FROM bonificacion WHERE dni_cliente_plus = '99999999K';