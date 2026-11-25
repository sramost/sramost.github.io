-- =====================================================================
-- Taller Integrador — Banco Andino
-- Solución grupal original; nombres omitidos en la publicación pública.
-- =====================================================================

-- =====================================================================
-- PARTE 1 — TRANSACCIONES, CONCURRENCIA Y BLOQUEOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- EJERCICIO 1.1 — Actualización perdida (lost update)
-- ---------------------------------------------------------------------
UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta = 1001;
COMMIT;

-- Sesión A (PASO 1)
SELECT id_cuenta, saldo, saldo_retenido, version
  FROM cuenta WHERE id_cuenta = 1001;

-- Sesión A (PASO 2)
UPDATE cuenta SET saldo = 700000 WHERE id_cuenta = 1001;
-- NO COMMIT

-- Sesión B (PASO 3)
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 1001;

-- Sesión B (PASO 4) — se bloquea
UPDATE cuenta SET saldo = 800000 WHERE id_cuenta = 1001;

-- Sesión A (PASO 5)
COMMIT;

-- Sesión B (PASO 6)
COMMIT;

-- Sesión A (PASO 8) — verificación: 800.000
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 1001;

-- ---------------------------------------------------------------------
-- EJERCICIO 1.2 — Bloqueo pesimista: SELECT ... FOR UPDATE
-- ---------------------------------------------------------------------
UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta = 1001;
COMMIT;

-- Sesión A (PASO 2)
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 1001 FOR UPDATE;

-- Sesión B (PASO 3) — se bloquea
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 1001 FOR UPDATE;

-- Sesión A (PASO 5)
UPDATE cuenta SET saldo = saldo - 300000 WHERE id_cuenta = 1001;
COMMIT;

-- Sesión B (PASO 6)
UPDATE cuenta SET saldo = saldo - 200000 WHERE id_cuenta = 1001;
COMMIT;

-- Verificación: 500.000
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 1001;

-- ---------------------------------------------------------------------
-- EJERCICIO 1.3 — Bloqueo optimista: columna de versión
-- ---------------------------------------------------------------------
UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta = 1001;
COMMIT;

-- Sesión A (PASO 2)
SELECT id_cuenta, saldo, version FROM cuenta WHERE id_cuenta = 1001;

-- Sesión B (PASO 3)
SELECT id_cuenta, saldo, version FROM cuenta WHERE id_cuenta = 1001;

-- Sesión B (PASO 4) — gana la carrera
UPDATE cuenta
   SET saldo   = saldo - 200000,
       version = version + 1
 WHERE id_cuenta = 1001
   AND version   = 0;
COMMIT;

-- Sesión A (PASO 5) — 0 filas actualizadas
UPDATE cuenta
   SET saldo   = saldo - 300000,
       version = version + 1
 WHERE id_cuenta = 1001
   AND version   = 0;
COMMIT;

-- Verificación
SELECT id_cuenta, saldo, version FROM cuenta WHERE id_cuenta = 1001;

-- ---------------------------------------------------------------------
-- EJERCICIO 1.4 — Repartir la cola con FOR UPDATE SKIP LOCKED
-- ---------------------------------------------------------------------
-- Sesión A (PASO 1)
SELECT id_tarea, id_transferencia
  FROM tarea_compensacion
 WHERE estado = 'PENDIENTE'
   AND ROWNUM <= 5
   FOR UPDATE SKIP LOCKED;

-- Sesión B (PASO 2)
SELECT id_tarea, id_transferencia
  FROM tarea_compensacion
 WHERE estado = 'PENDIENTE'
   AND ROWNUM <= 5
   FOR UPDATE SKIP LOCKED;

-- Sesión A (PASO 3)
UPDATE tarea_compensacion
   SET estado = 'COMPENSADA', tomada_por = 'PROCESO_A', fecha_toma = SYSTIMESTAMP
 WHERE id_tarea IN (1,2,3,4,5);
COMMIT;

-- Sesión B (PASO 4)
UPDATE tarea_compensacion
   SET estado = 'COMPENSADA', tomada_por = 'PROCESO_B', fecha_toma = SYSTIMESTAMP
 WHERE id_tarea IN (6,7,8,9,10);
COMMIT;

-- Verificación
SELECT tomada_por, COUNT(*) AS tareas
  FROM tarea_compensacion WHERE estado = 'COMPENSADA'
 GROUP BY tomada_por;

-- Verificación de duplicados
SELECT id_tarea, COUNT(*) FROM tarea_compensacion
 WHERE estado = 'COMPENSADA'
 GROUP BY id_tarea HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------
-- EJERCICIO 1.5 — Bloqueo por FK sin índice
-- ---------------------------------------------------------------------
-- Limpieza previa (si se repite)
DELETE FROM notificacion WHERE id_notificacion = 9000001;
COMMIT;

-- Sesión A (PASO 1) — sin COMMIT
INSERT INTO notificacion (id_notificacion, id_transferencia, canal, enviada)
VALUES (9000001, 900001, 'SMS', 'S');

-- Sesión B (PASO 2) — se bloquea
DELETE FROM transferencia WHERE id_transferencia = 900005;

-- Sesión A (PASO 3)
SELECT l.sid, l.type,
       DECODE(l.lmode, 0,'ninguno',1,'null',2,'RS',3,'RX',4,'S',5,'SRX',6,'X') AS tiene,
       DECODE(l.request,0,'-',1,'null',2,'RS',3,'RX',4,'S',5,'SRX',6,'X')      AS pide
  FROM v$lock l JOIN v$session s ON s.sid = l.sid
 WHERE s.username = USER AND l.type IN ('TX','TM');

-- Sesión A (PASO 4)
COMMIT;

-- Sesión B (PASO 5)
ROLLBACK;

-- Sesión A (PASO 6)
CREATE INDEX ix_notif_transferencia ON notificacion (id_transferencia);

-- ---------------------------------------------------------------------
-- EJERCICIO 1.6 — Interbloqueo (ORA-00060)
-- ---------------------------------------------------------------------
UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta IN (1001, 1002);
COMMIT;

-- Sesión A (PASO 1)
UPDATE cuenta SET saldo = saldo - 50000 WHERE id_cuenta = 1001;

-- Sesión B (PASO 2)
UPDATE cuenta SET saldo = saldo - 50000 WHERE id_cuenta = 1002;

-- Sesión A (PASO 3) — se bloquea
UPDATE cuenta SET saldo = saldo + 50000 WHERE id_cuenta = 1002;

-- Sesión B (PASO 4) — se bloquea; una recibe ORA-00060
UPDATE cuenta SET saldo = saldo + 50000 WHERE id_cuenta = 1001;

-- Sesión víctima
ROLLBACK;

-- Sesión que esperaba
ROLLBACK;

-- Verificación
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta IN (1001, 1002) ORDER BY id_cuenta;

-- Solución propuesta (regla de diseño: orden determinista)
SELECT id_cuenta
  FROM cuenta
 WHERE id_cuenta IN (1001, 1002)
 ORDER BY id_cuenta
   FOR UPDATE;

-- =====================================================================
-- PARTE 2 — ÍNDICES Y OPTIMIZACIÓN
-- =====================================================================

SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 1000

-- ---------------------------------------------------------------------
-- EJERCICIO 2.1 — Informe de la Superintendencia
-- ---------------------------------------------------------------------

-- PASO 1 — Consulta del informe mensual
-- Resultado: operaciones = 5.247, valor_total = 21.245.784.000,
--            ticket_promedio = 4.049.130
SELECT COUNT(*)          AS operaciones,
       SUM(valor)        AS valor_total,
       ROUND(AVG(valor)) AS ticket_promedio
  FROM transferencia
 WHERE fecha_transf >= DATE '2026-03-01'
   AND fecha_transf <  DATE '2026-04-01'
   AND estado        = 'APLICADA';

-- PASO 2 — Plan ANTES
-- Resultado: TABLE ACCESS FULL, COST = 377, Rows = 5.528
EXPLAIN PLAN FOR
SELECT COUNT(*), SUM(valor)
  FROM transferencia
 WHERE fecha_transf >= DATE '2026-03-01'
   AND fecha_transf <  DATE '2026-04-01'
   AND estado        = 'APLICADA';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- PASO 3 — Crear índice compuesto
CREATE INDEX ix_transf_fecha_estado ON transferencia (fecha_transf, estado);

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRANSFERENCIA', cascade => TRUE);

-- PASO 4 — Plan DESPUÉS
-- Resultado: INDEX RANGE SCAN, COST = 39, Rows = 5.364
EXPLAIN PLAN FOR
SELECT COUNT(*), SUM(valor)
  FROM transferencia
 WHERE fecha_transf >= DATE '2026-03-01'
   AND fecha_transf <  DATE '2026-04-01'
   AND estado        = 'APLICADA';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- PASO 5 — Comparar orden de columnas
CREATE INDEX ix_transf_estado_fecha ON transferencia (estado, fecha_transf);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRANSFERENCIA', cascade => TRUE);

-- Forzar (fecha_transf, estado): COST = 39
SELECT /*+ INDEX(t ix_transf_fecha_estado) */ COUNT(*)
  FROM transferencia t
 WHERE fecha_transf >= DATE '2026-03-01'
   AND fecha_transf <  DATE '2026-04-01'
   AND estado        = 'APLICADA';

-- Forzar (estado, fecha_transf): COST = 25
SELECT /*+ INDEX(t ix_transf_estado_fecha) */ COUNT(*)
  FROM transferencia t
 WHERE fecha_transf >= DATE '2026-03-01'
   AND fecha_transf <  DATE '2026-04-01'
   AND estado        = 'APLICADA';

-- Dejar solo el índice que se conserva
DROP INDEX ix_transf_estado_fecha;

-- ---------------------------------------------------------------------
-- EJERCICIO 2.2 — Función en el predicado
-- ---------------------------------------------------------------------

-- PASO 1 — Sin índice
-- Resultado: TABLE ACCESS FULL, COST = 49
EXPLAIN PLAN FOR
SELECT id_cliente, nombre, ciudad, segmento
  FROM cliente WHERE UPPER(nombre) = 'MARCELA ROJAS 4004';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST'));

-- PASO 2 — Índice "obvio" sobre la columna (no sirve)
-- Resultado: TABLE ACCESS FULL, COST = 49 (el índice no se usa)
CREATE INDEX ix_cliente_nombre ON cliente (nombre);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'CLIENTE', cascade => TRUE);

EXPLAIN PLAN FOR
SELECT id_cliente, nombre, ciudad, segmento
  FROM cliente WHERE UPPER(nombre) = 'MARCELA ROJAS 4004';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST'));

-- PASO 3 — Índice basado en función (FBI), sí sirve
-- Resultado: INDEX RANGE SCAN sobre IX_CLIENTE_NOMBRE_UPPER, COST = 2
CREATE INDEX ix_cliente_nombre_upper ON cliente (UPPER(nombre));
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'CLIENTE', cascade => TRUE);

EXPLAIN PLAN FOR
SELECT id_cliente, nombre, ciudad, segmento
  FROM cliente WHERE UPPER(nombre) = 'MARCELA ROJAS 4004';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST'));

-- PASO 4a — Mismo error con fechas: TRUNC (no filtra por índice)
-- Resultado: INDEX FAST FULL SCAN, COST = 238
EXPLAIN PLAN FOR
SELECT COUNT(*) FROM transferencia WHERE TRUNC(fecha_transf) = DATE '2026-03-15';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST'));

-- PASO 4b — Reescrito como rango (sí filtra por índice)
-- Resultado: INDEX RANGE SCAN, COST = 4
EXPLAIN PLAN FOR
SELECT COUNT(*) FROM transferencia
 WHERE fecha_transf >= DATE '2026-03-15'
   AND fecha_transf <  DATE '2026-03-16';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST'));

-- ---------------------------------------------------------------------
-- EJERCICIO 2.3 — Cuándo NO conviene un índice
-- ---------------------------------------------------------------------

-- PASO 1 — Filtro que devuelve el 62% de la tabla
-- Resultado: TABLE ACCESS FULL, COST = 377, Rows = 123K
CREATE INDEX ix_transf_estado ON transferencia (estado);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRANSFERENCIA', cascade => TRUE);

EXPLAIN PLAN FOR
SELECT COUNT(*), SUM(valor) FROM transferencia WHERE estado = 'APLICADA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- PASO 2 — Mismo índice, valor poco frecuente
-- Resultado: TABLE ACCESS FULL, COST = 377, Rows = 14K
EXPLAIN PLAN FOR
SELECT COUNT(*), SUM(valor) FROM transferencia WHERE estado = 'REVERSADA';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- PASO 3 — Estadísticas y clustering factor
SELECT column_name, num_distinct, num_nulls, density
  FROM user_tab_col_statistics
 WHERE table_name = 'TRANSFERENCIA'
   AND column_name IN ('ESTADO','FECHA_TRANSF','CUENTA_ORIGEN','CANAL');

SELECT index_name, num_rows, distinct_keys, clustering_factor, blevel, leaf_blocks
  FROM user_indexes WHERE table_name = 'TRANSFERENCIA';
  
  
 -- ---------------------------------------------------------------------
-- EJERCICIO 2.4 — Índice que evita tocar la tabla
-- ---------------------------------------------------------------------

-- PASO 1 — Consulta agregada (antes)
-- Resultado: HASH GROUP BY + TABLE ACCESS FULL, COST = 378
EXPLAIN PLAN FOR
SELECT cuenta_origen, COUNT(*) AS operaciones
  FROM transferencia
 WHERE fecha_transf >= DATE '2026-01-01'
   AND fecha_transf <  DATE '2026-04-01'
 GROUP BY cuenta_origen;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST'));

-- PASO 2 — Agregar la columna faltante al índice
-- Resultado: HASH GROUP BY + INDEX RANGE SCAN, COST = 92 (sin TABLE ACCESS)
CREATE INDEX ix_transf_fecha_origen ON transferencia (fecha_transf, cuenta_origen);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRANSFERENCIA', cascade => TRUE);

EXPLAIN PLAN FOR
SELECT cuenta_origen, COUNT(*) AS operaciones
  FROM transferencia
 WHERE fecha_transf >= DATE '2026-01-01'
   AND fecha_transf <  DATE '2026-04-01'
 GROUP BY cuenta_origen;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST'));

-- ---------------------------------------------------------------------
-- EJERCICIO 2.5 — Costo de escritura y lista definitiva
-- ---------------------------------------------------------------------

-- PASO 1 — Índices actuales
SELECT index_name, leaf_blocks,
       ROUND(leaf_blocks * 8192 / 1024 / 1024, 2) AS mb_aprox
  FROM user_indexes WHERE table_name = 'TRANSFERENCIA';

-- PASO 2 — INSERT con todos los índices: 2,092 segundos
SET TIMING ON
INSERT INTO transferencia
  (id_transferencia, cuenta_origen, cuenta_destino, fecha_transf, valor, canal, estado)
SELECT 1000000 + LEVEL,
       MOD(LEVEL, 15000) + 1,
       MOD(LEVEL, 15000) + 15001,
       DATE '2026-06-01' + MOD(LEVEL,30), 100000, 'APP', 'REGISTRADA'
  FROM dual CONNECT BY LEVEL <= 50000;
COMMIT;

-- PASO 3 — INSERT sin índices secundarios: 0,479 segundos
DROP INDEX ix_transf_fecha_estado;
DROP INDEX ix_transf_estado;
DROP INDEX ix_transf_fecha_origen;

INSERT INTO transferencia
  (id_transferencia, cuenta_origen, cuenta_destino, fecha_transf, valor, canal, estado)
SELECT 2000000 + LEVEL,
       MOD(LEVEL, 15000) + 1,
       MOD(LEVEL, 15000) + 15001,
       DATE '2026-06-01' + MOD(LEVEL,30), 100000, 'APP', 'REGISTRADA'
  FROM dual CONNECT BY LEVEL <= 50000;
COMMIT;

-- PASO 4 — Dejar el esquema como debe quedar
DELETE FROM transferencia WHERE id_transferencia >= 1000000;
COMMIT;

CREATE INDEX ix_transf_fecha_estado ON transferencia (fecha_transf, estado);
CREATE INDEX ix_transf_fecha_origen ON transferencia (fecha_transf, cuenta_origen);

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRANSFERENCIA', cascade => TRUE);

-- =====================================================================
-- PARTE 3 — SQL AVANZADO
-- =====================================================================

-- ---------------------------------------------------------------------
-- 3.1 PREGUNTA — Modelo por saldo
-- ---------------------------------------------------------------------

WITH captacion AS (
  SELECT f.id_producto  AS id_familia,
         f.nombre       AS familia,
         p.id_producto,
         p.nombre       AS producto,
         SUM(c.saldo)   AS saldo_captado,
         COUNT(*)       AS cuentas
    FROM cuenta c
    JOIN catalogo_producto p ON p.id_producto = c.id_producto
    JOIN catalogo_producto f ON f.id_producto = p.id_padre
   WHERE c.estado = 'ACTIVA'
   GROUP BY f.id_producto, f.nombre, p.id_producto, p.nombre
)
SELECT familia,
       producto,
       ROUND(saldo_captado) AS saldo_captado,
       ROW_NUMBER() OVER (PARTITION BY id_familia
                          ORDER BY saldo_captado DESC, id_producto) AS row_number,
       RANK()       OVER (PARTITION BY id_familia
                          ORDER BY saldo_captado DESC)              AS rank,
       DENSE_RANK() OVER (PARTITION BY id_familia
                          ORDER BY saldo_captado DESC)              AS dense_rank
  FROM captacion
 ORDER BY familia, saldo_captado DESC;

-- ---------------------------------------------------------------------
-- 3.1 PREGUNTA — Modelo por cuentas
-- ---------------------------------------------------------------------

WITH captacion AS (
  SELECT f.id_producto  AS id_familia,
         f.nombre       AS familia,
         p.id_producto,
         p.nombre       AS producto,
         SUM(c.saldo)   AS saldo_captado,
         COUNT(*)       AS cuentas
    FROM cuenta c
    JOIN catalogo_producto p ON p.id_producto = c.id_producto
    JOIN catalogo_producto f ON f.id_producto = p.id_padre
   WHERE c.estado = 'ACTIVA'
   GROUP BY f.id_producto, f.nombre, p.id_producto, p.nombre
)
SELECT familia,
       producto,
       cuentas,
       ROW_NUMBER() OVER (PARTITION BY id_familia
                          ORDER BY cuentas DESC, id_producto) AS row_number,
       RANK()       OVER (PARTITION BY id_familia
                          ORDER BY cuentas DESC)              AS rank,
       DENSE_RANK() OVER (PARTITION BY id_familia
                          ORDER BY cuentas DESC)              AS dense_rank
  FROM captacion
 ORDER BY familia, cuentas DESC, producto;

-- ---------------------------------------------------------------------
-- 3.1 ESCRIBA — Top 3 productos por familia con porcentaje
-- ---------------------------------------------------------------------

WITH captacion AS (
  SELECT f.id_producto  AS id_familia,
         f.nombre       AS familia,
         p.id_producto,
         p.nombre       AS producto,
         SUM(c.saldo)   AS saldo_captado,
         COUNT(*)       AS cuentas
    FROM cuenta c
    JOIN catalogo_producto p ON p.id_producto = c.id_producto
    JOIN catalogo_producto f ON f.id_producto = p.id_padre
   WHERE c.estado = 'ACTIVA'
   GROUP BY f.id_producto, f.nombre, p.id_producto, p.nombre
),
clasificado AS (
  SELECT v.*,
         ROW_NUMBER() OVER (PARTITION BY id_familia
                            ORDER BY saldo_captado DESC, id_producto)       AS puesto,
         ROUND(100 * RATIO_TO_REPORT(saldo_captado)
                       OVER (PARTITION BY id_familia), 2)                   AS pct_familia,
         ROUND(100 * saldo_captado
                   / SUM(saldo_captado) OVER (PARTITION BY id_familia), 2)  AS pct_familia_sum
    FROM captacion v
)
SELECT familia, producto, cuentas,
       ROUND(saldo_captado) AS saldo_captado,
       pct_familia, pct_familia_sum, puesto
  FROM clasificado
 WHERE puesto <= 3
 ORDER BY familia, puesto;

-- ---------------------------------------------------------------------
-- 3.2.1 — Modelo ROWS vs RANGE
-- ---------------------------------------------------------------------

SELECT TRUNC(fecha_transf) AS dia, id_transferencia, valor,
       SUM(valor) OVER (ORDER BY TRUNC(fecha_transf)
                        ROWS  BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS con_rows,
       SUM(valor) OVER (ORDER BY TRUNC(fecha_transf)
                        RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS con_range
  FROM transferencia
 WHERE fecha_transf >= DATE '2026-03-01'
   AND fecha_transf <  DATE '2026-03-03'
   AND estado = 'APLICADA'
 ORDER BY dia, id_transferencia;

-- ---------------------------------------------------------------------
-- 3.2 ESCRIBA — Evolución mensual con acumulado, LAG y promedio móvil
-- ---------------------------------------------------------------------

WITH mensual AS (
  SELECT TRUNC(fecha_transf, 'MM') AS mes,
         SUM(valor)                AS valor_transferido,
         COUNT(*)                  AS operaciones
    FROM transferencia
   WHERE fecha_transf >= DATE '2026-01-01'
     AND fecha_transf <  DATE '2027-01-01'
     AND estado = 'APLICADA'
   GROUP BY TRUNC(fecha_transf, 'MM')
)
SELECT TO_CHAR(mes, 'YYYY-MM') AS mes,
       operaciones,
       ROUND(valor_transferido) AS valor,
       ROUND(SUM(valor_transferido) OVER (PARTITION BY EXTRACT(YEAR FROM mes)
                                          ORDER BY mes
                                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS acumulado_anio,
       ROUND(LAG(valor_transferido) OVER (ORDER BY mes))                                     AS mes_anterior,
       ROUND(100 * (valor_transferido - LAG(valor_transferido) OVER (ORDER BY mes))
                 / NULLIF(LAG(valor_transferido) OVER (ORDER BY mes), 0), 1)                 AS var_pct,
       CASE WHEN COUNT(*) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) = 3
            THEN ROUND(AVG(valor_transferido) OVER (ORDER BY mes
                                                    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW))
       END                                                                                    AS prom_movil_3m
  FROM mensual
 ORDER BY mes;

-- ---------------------------------------------------------------------
-- 3.3 — Saldo por línea de negocio (CTE recursiva)
-- ---------------------------------------------------------------------

WITH arbol (id_producto, id_linea, linea, nivel) AS (
  SELECT id_producto, id_producto, nombre, 1
    FROM catalogo_producto
   WHERE id_padre IS NULL
  UNION ALL
  SELECT h.id_producto, a.id_linea, a.linea, a.nivel + 1
    FROM catalogo_producto h
    JOIN arbol a ON h.id_padre = a.id_producto
)
SELECT a.linea                                                    AS linea_negocio,
       COUNT(CASE WHEN c.estado = 'ACTIVA' THEN 1 END)            AS cuentas_activas,
       ROUND(SUM(CASE WHEN c.estado = 'ACTIVA' THEN c.saldo END)) AS saldo_cuentas_activas,
       COUNT(c.id_cuenta)                                         AS cuentas_total,
       ROUND(SUM(c.saldo))                                        AS saldo_total
  FROM arbol a
  LEFT JOIN cuenta c ON c.id_producto = a.id_producto
 GROUP BY a.id_linea, a.linea
 ORDER BY saldo_total DESC NULLS LAST;

-- ---------------------------------------------------------------------
-- 3.3 — Saldo por línea de negocio (CONNECT BY)
-- ---------------------------------------------------------------------

SELECT linea, COUNT(*) AS cuentas_total, ROUND(SUM(c.saldo)) AS saldo_total
  FROM (SELECT CONNECT_BY_ROOT nombre AS linea, id_producto
          FROM catalogo_producto
         START WITH id_padre IS NULL
       CONNECT BY PRIOR id_producto = id_padre) h
  JOIN cuenta c ON c.id_producto = h.id_producto
 GROUP BY linea
 ORDER BY saldo_total DESC;

-- ---------------------------------------------------------------------
-- 3.4 — MERGE de ajustes del cierre mensual
--
-- ADVERTENCIA: el MERGE modelo del guion ya aplicó y confirmó los
-- ajustes. Ejecutar este y confirmarlo los aplicaría DOS VECES. Por eso
-- la demostración termina en ROLLBACK.
-- ---------------------------------------------------------------------

-- 0. Caso de prueba: cuota mayor que el saldo de la cuenta 1001
INSERT INTO ajuste_saldo (id_cuenta, delta, concepto)
VALUES (1001, -5000000, 'CUOTA MANEJO');

-- 1. Bloqueo ordenado de las cuentas afectadas
SELECT c.id_cuenta
  FROM cuenta c
 WHERE c.id_cuenta IN (SELECT id_cuenta FROM ajuste_saldo)
 ORDER BY c.id_cuenta
   FOR UPDATE;

-- 2. Identificar las que NO se pueden aplicar completas
SELECT c.id_cuenta,
       c.saldo                AS saldo_actual,
       a.delta                AS ajuste_neto,
       c.saldo + a.delta      AS saldo_resultante,
       -(c.saldo + a.delta)   AS faltante
  FROM cuenta c
  JOIN (SELECT id_cuenta, SUM(delta) AS delta
          FROM ajuste_saldo GROUP BY id_cuenta) a
    ON a.id_cuenta = c.id_cuenta
 WHERE c.saldo + a.delta < 0
 ORDER BY faltante DESC;
--   Esperado: la cuenta 1001.

-- 3. Aplicar SOLO los que alcanzan
MERGE INTO cuenta c
USING (SELECT id_cuenta, SUM(delta) AS delta
         FROM ajuste_saldo GROUP BY id_cuenta) a
   ON (c.id_cuenta = a.id_cuenta)
 WHEN MATCHED THEN
   UPDATE SET c.saldo   = c.saldo + a.delta,
              c.version = c.version + 1
    WHERE c.saldo + a.delta >= 0;
--   Esperado: filas fusionadas = (cuentas en AJUSTE_SALDO) - (excluidas)

-- 4. Verificar que la 1001 NO se tocó
SELECT id_cuenta, saldo, version FROM cuenta WHERE id_cuenta = 1001;

-- 5. Deshacer: esto era una demostración (ver advertencia)
ROLLBACK;

-- ---------------------------------------------------------------------
-- 3.5 — Informe de clientes PREFERENCIAL sin transferencias en 120 días
--
--   a) Solo 10.000 de las 30.000 cuentas aparecen alguna vez como ORIGEN:
--      muchos clientes NUNCA han transferido. Un JOIN interno los hace
--      desaparecer, y son precisamente los más inactivos -> LEFT JOIN,
--      contando sus días desde la vinculación.
--   b) El setup genera fechas hasta el 31-dic-2026: hay transferencias
--      con fecha FUTURA. Sin filtrarlas, casi nadie aparecería inactivo
--      -> fecha_transf <= SYSDATE.
--   c) Saldo y transferencias se agregan POR SEPARADO: unirlos en un solo
--      GROUP BY multiplicaría el saldo por el número de transferencias.
--
-- CRITERIO: se considera "actividad" la transferencia que el cliente
-- ORIGINA. Recibir dinero no indica que el cliente use el banco.
-- ---------------------------------------------------------------------

WITH cuentas_cliente AS (
  SELECT c.id_cliente,
         SUM(c.saldo)                   AS saldo_total,
         COUNT(DISTINCT c.id_producto)  AS productos,
         LISTAGG(DISTINCT p.nombre, ', ') WITHIN GROUP (ORDER BY p.nombre) AS lista_productos
    FROM cuenta c
    JOIN catalogo_producto p ON p.id_producto = c.id_producto
   WHERE c.estado = 'ACTIVA'
   GROUP BY c.id_cliente
),
ultima_transferencia AS (
  SELECT c.id_cliente, MAX(t.fecha_transf) AS ultima
    FROM cuenta c
    JOIN transferencia t ON t.cuenta_origen = c.id_cuenta
   WHERE t.fecha_transf <= SYSDATE
   GROUP BY c.id_cliente
)
SELECT cl.id_cliente,
       cl.nombre,
       cl.ciudad,
       TO_CHAR(u.ultima, 'YYYY-MM-DD')                                 AS ultima_transferencia,
       TRUNC(SYSDATE) - TRUNC(COALESCE(u.ultima, cl.fecha_vinculacion)) AS dias_inactivo,
       CASE WHEN u.ultima IS NULL
            THEN 'Nunca ha transferido (días desde la vinculación)'
       END                                                             AS observacion,
       ROUND(cc.saldo_total)                                           AS saldo_total,
       cc.productos,
       cc.lista_productos
  FROM cliente cl
  JOIN cuentas_cliente cc          ON cc.id_cliente = cl.id_cliente
  LEFT JOIN ultima_transferencia u ON u.id_cliente  = cl.id_cliente
 WHERE cl.segmento = 'PREFERENCIAL'
   AND (u.ultima IS NULL OR u.ultima < SYSDATE - 120)
 ORDER BY dias_inactivo DESC, saldo_total DESC;
 
-- =====================================================================
-- PARTE 4 — RETO INTEGRADOR
-- =====================================================================

-- ---------------------------------------------------------------------
-- PIEZA 1 — Secuencia defectuosa que ejecuta el core
-- (reproducida tal como está en el script, sin corregir)
-- ---------------------------------------------------------------------

-- Preparación
UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta IN (1001, 1002);
UPDATE transferencia SET estado = 'REGISTRADA' WHERE id_transferencia = 950001;
DELETE FROM movimiento WHERE id_movimiento IN (9500001, 9500002);
COMMIT;

-- Secuencia defectuosa (NO corregida)
SELECT saldo FROM cuenta WHERE id_cuenta = 1001;
UPDATE cuenta SET saldo = 700000 WHERE id_cuenta = 1001;
COMMIT;

SELECT saldo FROM cuenta WHERE id_cuenta = 1002;
UPDATE cuenta SET saldo = 1300000 WHERE id_cuenta = 1002;
COMMIT;

INSERT INTO movimiento (id_movimiento, id_cuenta, id_transferencia, fecha_mov, tipo, valor)
VALUES (9500001, 1001, 950001, SYSDATE, 'DEBITO', 300000);
COMMIT;

INSERT INTO movimiento (id_movimiento, id_cuenta, id_transferencia, fecha_mov, tipo, valor)
VALUES (9500002, 1002, 950001, SYSDATE, 'CREDITO', 300000);
COMMIT;

UPDATE transferencia SET estado = 'APLICADA' WHERE id_transferencia = 950001;
COMMIT;

-- Verificación del resultado de la secuencia defectuosa
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta IN (1001,1002) ORDER BY id_cuenta;
SELECT id_transferencia, estado FROM transferencia WHERE id_transferencia = 950001;

-- ---------------------------------------------------------------------
-- REPRODUCCIÓN DEL DEFECTO DE CONCURRENCIA
-- (dos conexiones simultáneas sobre la misma cuenta)
-- ---------------------------------------------------------------------

-- Preparación
UPDATE cuenta SET saldo = 1000000 WHERE id_cuenta = 1001;
COMMIT;

-- Sesión A: lee y escribe SIN COMMIT
SELECT saldo FROM cuenta WHERE id_cuenta = 1001;
UPDATE cuenta SET saldo = 700000 WHERE id_cuenta = 1001;
-- NO COMMIT

-- Sesión B: lee y escribe (se bloquea)
SELECT saldo FROM cuenta WHERE id_cuenta = 1001;
UPDATE cuenta SET saldo = 800000 WHERE id_cuenta = 1001;
-- se bloquea

-- Sesión A
COMMIT;

-- Sesión B
COMMIT;

-- Verificación de la pérdida
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta = 1001;
-- Resultado: 800000 (debería ser 500000)

-- ---------------------------------------------------------------------
-- REPRODUCCIÓN DEL DEFECTO DE TRANSACCIONALIDAD
-- (falla simulada entre débito y crédito)
-- ---------------------------------------------------------------------

-- Preparación
UPDATE cuenta SET saldo = 1000000 WHERE id_cuenta IN (1001, 1002);
UPDATE transferencia SET estado = 'REGISTRADA' WHERE id_transferencia = 950001;
DELETE FROM movimiento WHERE id_movimiento IN (9500001, 9500002);
COMMIT;

-- Débito del origen (se confirma)
UPDATE cuenta SET saldo = 700000 WHERE id_cuenta = 1001;
COMMIT;

-- Simular falla: NO se ejecuta el crédito

-- Verificación del estado a medias
SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta IN (1001,1002) ORDER BY id_cuenta;
SELECT id_transferencia, estado FROM transferencia WHERE id_transferencia = 950001;
-- Resultado: 1001=700000, 1002=1000000, transferencia=REGISTRADA

-- ---------------------------------------------------------------------
-- LIMPIEZA DEL ESCENARIO
-- ---------------------------------------------------------------------

UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta IN (1001, 1002);
UPDATE transferencia SET estado = 'REGISTRADA' WHERE id_transferencia = 950001;
DELETE FROM movimiento WHERE id_movimiento IN (9500001, 9500002, 9500003, 9500004);
COMMIT;

-- ---------------------------------------------------------------------
-- PIEZA 2 — Consulta del tablero (original, sin optimizar)
-- ---------------------------------------------------------------------

SELECT s.ciudad,
       COUNT(DISTINCT t.id_transferencia)  AS operaciones,
       ROUND(SUM(t.valor))                 AS valor_total,
       ROUND(AVG(t.valor))                 AS ticket
  FROM transferencia t
  JOIN cuenta        c ON c.id_cuenta   = t.cuenta_origen
  JOIN sucursal      s ON s.id_sucursal = c.id_sucursal
 WHERE TO_CHAR(t.fecha_transf, 'YYYY-MM') = '2026-03'
   AND t.estado = 'APLICADA'
 GROUP BY s.ciudad
 ORDER BY valor_total DESC;

-- ---------------------------------------------------------------------
-- LITERAL B — SECUENCIA CORREGIDA
-- ---------------------------------------------------------------------

-- Preparación

UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta IN (1001, 1002);
UPDATE transferencia SET estado = 'REGISTRADA' WHERE id_transferencia = 950001;
DELETE FROM movimiento WHERE id_movimiento IN (9500001, 9500002, 9500003, 9500004);
COMMIT


-- ---------------------------------------------------------------------
-- Sesión A: transferencia 1001 -> 1002
-- ---------------------------------------------------------------------

-- 1. Bloquear las dos cuentas en orden determinista

SELECT id_cuenta
     FROM cuenta
    WHERE id_cuenta IN (1001, 1002)
    ORDER BY id_cuenta
     FOR UPDATE;



-- 2. Débito del origen 

UPDATE cuenta SET saldo = saldo - 300000 WHERE id_cuenta = 1001 AND saldo >= 300000;

-- 3. Crédito del destino 

UPDATE cuenta SET saldo = saldo + 300000 WHERE id_cuenta = 1002;

-- 4. Movimientos de A

INSERT INTO movimiento (id_movimiento, id_cuenta, id_trasferencia, fecha_mov, tipo, valor)
VALUES(9500001, 1001, 950001, SYSDATE, 'DEBITO', 300000);

INSERT INTO movimiento (id_movimiento, id_cuenta, id_transferencia, fecha_mov, tipo, valor)
VALUES (9500002, 1002, 9500001, SYSDATE, 'CREDITO', 300000);


-- 5. Cambio de estado condicionado

UPDATE transferencia SET estado = 'APLICADA'
    WHERE id_transferencia = 9500001 AND estado = 'REGISTRADA';


-- 6. COMMIT al final
COMMIT;

-- ---------------------------------------------------------------------
-- Sesión B: transferencia 1002 -> 1001 (sentido cruzado)
-- ---------------------------------------------------------------------

-- 1. Bloquear las dos cuentas en el MISMO orden (se bloquea hasta que A confirme)
SELECT id_cuenta
  FROM cuenta
 WHERE id_cuenta IN (1001, 1002)
 ORDER BY id_cuenta
   FOR UPDATE;

-- 2. Débito del origen (1002)
UPDATE cuenta SET saldo = saldo - 300000 WHERE id_cuenta = 1002 AND saldo >= 300000;

-- 3. Crédito del destino (1001)
UPDATE cuenta SET saldo = saldo + 300000 WHERE id_cuenta = 1001;

-- 4. Movimientos de B (IDs distintos a los de A)
INSERT INTO movimiento (id_movimiento, id_cuenta, id_transferencia, fecha_mov, tipo, valor)
VALUES (9500003, 1002, 950001, SYSDATE, 'DEBITO', 300000);

INSERT INTO movimiento (id_movimiento, id_cuenta, id_transferencia, fecha_mov, tipo, valor)
VALUES (9500004, 1001, 950001, SYSDATE, 'CREDITO', 300000);

-- 5. Cambio de estado condicionado
UPDATE transferencia SET estado = 'APLICADA'
 WHERE id_transferencia = 950001 AND estado = 'REGISTRADA';

-- 6. Un solo COMMIT al final
COMMIT;

-- ---------------------------------------------------------------------
-- Verificación final
-- ---------------------------------------------------------------------

SELECT id_cuenta, saldo FROM cuenta WHERE id_cuenta IN (1001,1002) ORDER BY id_cuenta;

SELECT id_transferencia, estado FROM transferencia WHERE id_transferencia = 950001;

SELECT id_movimiento, id_cuenta, tipo, valor
  FROM movimiento WHERE id_movimiento IN (9500001, 9500002, 9500003, 9500004)
 ORDER BY id_movimiento;

-- ---------------------------------------------------------------------
-- Limpieza del escenario
-- ---------------------------------------------------------------------

UPDATE cuenta SET saldo = 1000000, version = 0 WHERE id_cuenta IN (1001, 1002);
UPDATE transferencia SET estado = 'REGISTRADA' WHERE id_transferencia = 950001;
DELETE FROM movimiento WHERE id_movimiento IN (9500001, 9500002, 9500003, 9500004);
COMMIT;


-- ---------------------------------------------------------------------
-- LITERAL C — CONSULTA DEL TABLERO OPTIMIZADA
-- ---------------------------------------------------------------------

-- PASO 1 — Consulta original
SELECT s.ciudad,
       COUNT(DISTINCT t.id_transferencia)  AS operaciones,
       ROUND(SUM(t.valor))                 AS valor_total,
       ROUND(AVG(t.valor))                 AS ticket
  FROM transferencia t
  JOIN cuenta        c ON c.id_cuenta   = t.cuenta_origen
  JOIN sucursal      s ON s.id_sucursal = c.id_sucursal
 WHERE TO_CHAR(t.fecha_transf, 'YYYY-MM') = '2026-03'
   AND t.estado = 'APLICADA'
 GROUP BY s.ciudad
 ORDER BY valor_total DESC;

-- PASO 2 — Plan antes (COST = 623, TABLE ACCESS FULL)
EXPLAIN PLAN FOR
SELECT s.ciudad,
       COUNT(DISTINCT t.id_transferencia)  AS operaciones,
       ROUND(SUM(t.valor))                 AS valor_total,
       ROUND(AVG(t.valor))                 AS ticket
  FROM transferencia t
  JOIN cuenta        c ON c.id_cuenta   = t.cuenta_origen
  JOIN sucursal      s ON s.id_sucursal = c.id_sucursal
 WHERE TO_CHAR(t.fecha_transf, 'YYYY-MM') = '2026-03'
   AND t.estado = 'APLICADA'
 GROUP BY s.ciudad
 ORDER BY valor_total DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- PASO 3 — Consulta optimizada (rango en vez de TO_CHAR)
SELECT s.ciudad,
       COUNT(DISTINCT t.id_transferencia)  AS operaciones,
       ROUND(SUM(t.valor))                 AS valor_total,
       ROUND(AVG(t.valor))                 AS ticket
  FROM transferencia t
  JOIN cuenta        c ON c.id_cuenta   = t.cuenta_origen
  JOIN sucursal      s ON s.id_sucursal = c.id_sucursal
 WHERE t.fecha_transf >= DATE '2026-03-01'
   AND t.fecha_transf <  DATE '2026-04-01'
   AND t.estado = 'APLICADA'
 GROUP BY s.ciudad
 ORDER BY valor_total DESC;

-- PASO 4 — Plan después de reescribir (COST = 621, aún TABLE ACCESS FULL)
EXPLAIN PLAN FOR
SELECT s.ciudad,
       COUNT(DISTINCT t.id_transferencia)  AS operaciones,
       ROUND(SUM(t.valor))                 AS valor_total,
       ROUND(AVG(t.valor))                 AS ticket
  FROM transferencia t
  JOIN cuenta        c ON c.id_cuenta   = t.cuenta_origen
  JOIN sucursal      s ON s.id_sucursal = c.id_sucursal
 WHERE t.fecha_transf >= DATE '2026-03-01'
   AND t.fecha_transf <  DATE '2026-04-01'
   AND t.estado = 'APLICADA'
 GROUP BY s.ciudad
 ORDER BY valor_total DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));

-- PASO 5 — Índice que cubre la consulta del tablero
CREATE INDEX ix_transf_fecha_estado_cuenta
  ON transferencia (fecha_transf, estado, cuenta_origen, valor);

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'TRANSFERENCIA', cascade => TRUE);

-- PASO 6 — Plan final (COST = 126, INDEX RANGE SCAN)
EXPLAIN PLAN FOR
SELECT s.ciudad,
       COUNT(DISTINCT t.id_transferencia)  AS operaciones,
       ROUND(SUM(t.valor))                 AS valor_total,
       ROUND(AVG(t.valor))                 AS ticket
  FROM transferencia t
  JOIN cuenta        c ON c.id_cuenta   = t.cuenta_origen
  JOIN sucursal      s ON s.id_sucursal = c.id_sucursal
 WHERE t.fecha_transf >= DATE '2026-03-01'
   AND t.fecha_transf <  DATE '2026-04-01'
   AND t.estado = 'APLICADA'
 GROUP BY s.ciudad
 ORDER BY valor_total DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(format => 'BASIC +COST +ROWS'));
  