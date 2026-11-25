--------------------------------------------------------------------------------
-- UNIVERSIDAD EL BOSQUE — INGENIERIA DE SISTEMAS
-- TALLER PL/SQL — MODELO DE INVENTARIO Y VENTAS
-- Script 01: creacion del esquema y carga de datos
--
-- Ejecutar este script COMPLETO, con la opcion Run Script, antes de iniciar
-- el taller. Es reejecutable: vuelve a dejar el esquema en su estado inicial.
--
-- No modificar la estructura de las tablas ni los datos cargados.
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

--------------------------------------------------------------------------------
-- LIMPIEZA
--------------------------------------------------------------------------------
BEGIN
  FOR r IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('LOG_ERRORES','AUDITORIA_PRECIO','MOVIMIENTO_INVENTARIO',
                                 'DETALLE_PEDIDO','PEDIDO','EXISTENCIA','PRODUCTO',
                                 'CATEGORIA','BODEGA','CLIENTE')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || r.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;

  FOR s IN (SELECT sequence_name FROM user_sequences
            WHERE sequence_name IN ('SEQ_PRODUCTO','SEQ_CLIENTE','SEQ_PEDIDO',
                                    'SEQ_MOVIMIENTO','SEQ_AUDITORIA','SEQ_LOG')) LOOP
    EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
  END LOOP;
END;
/

--------------------------------------------------------------------------------
-- TABLAS MAESTRAS
--------------------------------------------------------------------------------
CREATE TABLE CATEGORIA (
  id_categoria   NUMBER(4)      NOT NULL,
  nombre         VARCHAR2(60)   NOT NULL,
  margen_minimo  NUMBER(5,2)    DEFAULT 10 NOT NULL,
  CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
  CONSTRAINT uk_categoria_nombre UNIQUE (nombre),
  CONSTRAINT ck_categoria_margen CHECK (margen_minimo BETWEEN 0 AND 100)
);

CREATE TABLE BODEGA (
  id_bodega  NUMBER(4)     NOT NULL,
  nombre     VARCHAR2(60)  NOT NULL,
  ciudad     VARCHAR2(40)  NOT NULL,
  activa     CHAR(1)       DEFAULT 'S' NOT NULL,
  CONSTRAINT pk_bodega PRIMARY KEY (id_bodega),
  CONSTRAINT ck_bodega_activa CHECK (activa IN ('S','N'))
);

CREATE TABLE PRODUCTO (
  id_producto      NUMBER(6)      NOT NULL,
  codigo           VARCHAR2(20)   NOT NULL,
  nombre           VARCHAR2(100)  NOT NULL,
  id_categoria     NUMBER(4)      NOT NULL,
  precio_unitario  NUMBER(12,2)   NOT NULL,
  costo_unitario   NUMBER(12,2)   NOT NULL,
  stock_minimo     NUMBER(8)      DEFAULT 0 NOT NULL,
  activo           CHAR(1)        DEFAULT 'S' NOT NULL,
  CONSTRAINT pk_producto PRIMARY KEY (id_producto),
  CONSTRAINT uk_producto_codigo UNIQUE (codigo),
  CONSTRAINT fk_producto_categoria FOREIGN KEY (id_categoria)
             REFERENCES CATEGORIA (id_categoria),
  CONSTRAINT ck_producto_precio CHECK (precio_unitario > 0),
  CONSTRAINT ck_producto_costo  CHECK (costo_unitario > 0),
  CONSTRAINT ck_producto_activo CHECK (activo IN ('S','N'))
);

CREATE TABLE CLIENTE (
  id_cliente       NUMBER(6)      NOT NULL,
  documento        VARCHAR2(20)   NOT NULL,
  nombre           VARCHAR2(100)  NOT NULL,
  ciudad           VARCHAR2(40)   NOT NULL,
  cupo_credito     NUMBER(12,2)   DEFAULT 0 NOT NULL,
  saldo_pendiente  NUMBER(12,2)   DEFAULT 0 NOT NULL,
  activo           CHAR(1)        DEFAULT 'S' NOT NULL,
  CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
  CONSTRAINT uk_cliente_documento UNIQUE (documento),
  CONSTRAINT ck_cliente_cupo   CHECK (cupo_credito >= 0),
  CONSTRAINT ck_cliente_saldo  CHECK (saldo_pendiente >= 0),
  CONSTRAINT ck_cliente_activo CHECK (activo IN ('S','N'))
);

--------------------------------------------------------------------------------
-- TABLAS TRANSACCIONALES
--------------------------------------------------------------------------------
CREATE TABLE EXISTENCIA (
  id_bodega    NUMBER(4)  NOT NULL,
  id_producto  NUMBER(6)  NOT NULL,
  cantidad     NUMBER(10) DEFAULT 0 NOT NULL,
  CONSTRAINT pk_existencia PRIMARY KEY (id_bodega, id_producto),
  CONSTRAINT fk_existencia_bodega   FOREIGN KEY (id_bodega)
             REFERENCES BODEGA (id_bodega),
  CONSTRAINT fk_existencia_producto FOREIGN KEY (id_producto)
             REFERENCES PRODUCTO (id_producto),
  CONSTRAINT ck_existencia_cantidad CHECK (cantidad >= 0)
);

CREATE TABLE PEDIDO (
  id_pedido    NUMBER(10)    NOT NULL,
  id_cliente   NUMBER(6)     NOT NULL,
  fecha_pedido DATE          DEFAULT SYSDATE NOT NULL,
  estado       VARCHAR2(15)  DEFAULT 'BORRADOR' NOT NULL,
  total        NUMBER(14,2)  DEFAULT 0 NOT NULL,
  CONSTRAINT pk_pedido PRIMARY KEY (id_pedido),
  CONSTRAINT fk_pedido_cliente FOREIGN KEY (id_cliente)
             REFERENCES CLIENTE (id_cliente),
  CONSTRAINT ck_pedido_estado CHECK (estado IN ('BORRADOR','CONFIRMADO','ANULADO')),
  CONSTRAINT ck_pedido_total  CHECK (total >= 0)
);

CREATE TABLE DETALLE_PEDIDO (
  id_pedido        NUMBER(10)    NOT NULL,
  linea            NUMBER(4)     NOT NULL,
  id_producto      NUMBER(6)     NOT NULL,
  id_bodega        NUMBER(4)     NOT NULL,
  cantidad         NUMBER(8)     NOT NULL,
  precio_unitario  NUMBER(12,2)  NOT NULL,
  subtotal         NUMBER(14,2)  NOT NULL,
  CONSTRAINT pk_detalle_pedido PRIMARY KEY (id_pedido, linea),
  CONSTRAINT fk_detalle_pedido   FOREIGN KEY (id_pedido)
             REFERENCES PEDIDO (id_pedido),
  CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto)
             REFERENCES PRODUCTO (id_producto),
  CONSTRAINT fk_detalle_bodega   FOREIGN KEY (id_bodega)
             REFERENCES BODEGA (id_bodega),
  CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
  CONSTRAINT ck_detalle_precio   CHECK (precio_unitario > 0)
);

CREATE TABLE MOVIMIENTO_INVENTARIO (
  id_movimiento  NUMBER(12)    NOT NULL,
  id_producto    NUMBER(6)     NOT NULL,
  id_bodega      NUMBER(4)     NOT NULL,
  tipo           VARCHAR2(10)  NOT NULL,
  cantidad       NUMBER(10)    NOT NULL,
  fecha_mov      DATE          DEFAULT SYSDATE NOT NULL,
  id_pedido      NUMBER(10),
  usuario_bd     VARCHAR2(40)  DEFAULT USER NOT NULL,
  observacion    VARCHAR2(200),
  CONSTRAINT pk_movimiento PRIMARY KEY (id_movimiento),
  CONSTRAINT fk_mov_producto FOREIGN KEY (id_producto)
             REFERENCES PRODUCTO (id_producto),
  CONSTRAINT fk_mov_bodega   FOREIGN KEY (id_bodega)
             REFERENCES BODEGA (id_bodega),
  CONSTRAINT ck_mov_tipo     CHECK (tipo IN ('ENTRADA','SALIDA','AJUSTE')),
  CONSTRAINT ck_mov_cantidad CHECK (cantidad > 0)
);

--------------------------------------------------------------------------------
-- TABLAS DE AUDITORIA Y CONTROL
--------------------------------------------------------------------------------
CREATE TABLE AUDITORIA_PRECIO (
  id_auditoria     NUMBER(12)    NOT NULL,
  id_producto      NUMBER(6)     NOT NULL,
  precio_anterior  NUMBER(12,2)  NOT NULL,
  precio_nuevo     NUMBER(12,2)  NOT NULL,
  variacion_pct    NUMBER(8,2),
  usuario_bd       VARCHAR2(40)  DEFAULT USER NOT NULL,
  fecha_cambio     DATE          DEFAULT SYSDATE NOT NULL,
  CONSTRAINT pk_auditoria_precio PRIMARY KEY (id_auditoria)
);

CREATE TABLE LOG_ERRORES (
  id_log       NUMBER(12)      NOT NULL,
  origen       VARCHAR2(60)    NOT NULL,
  codigo_error NUMBER,
  mensaje      VARCHAR2(500),
  detalle      VARCHAR2(500),
  usuario_bd   VARCHAR2(40)    DEFAULT USER NOT NULL,
  fecha_log    TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
  CONSTRAINT pk_log_errores PRIMARY KEY (id_log)
);

--------------------------------------------------------------------------------
-- SECUENCIAS
--------------------------------------------------------------------------------
CREATE SEQUENCE SEQ_PRODUCTO    START WITH 1000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_CLIENTE     START WITH 500  INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_PEDIDO      START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_MOVIMIENTO  START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_AUDITORIA   START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_LOG         START WITH 1    INCREMENT BY 1 NOCACHE;

--------------------------------------------------------------------------------
-- VISTA
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW V_STOCK_CONSOLIDADO AS
SELECT p.id_producto,
       p.codigo,
       p.nombre         AS producto,
       c.nombre         AS categoria,
       p.precio_unitario,
       p.stock_minimo,
       NVL(SUM(e.cantidad), 0) AS stock_total
FROM   PRODUCTO p
       JOIN CATEGORIA c ON c.id_categoria = p.id_categoria
       LEFT JOIN EXISTENCIA e ON e.id_producto = p.id_producto
GROUP BY p.id_producto, p.codigo, p.nombre, c.nombre,
         p.precio_unitario, p.stock_minimo;

--------------------------------------------------------------------------------
-- CATEGORIAS
--------------------------------------------------------------------------------
INSERT INTO CATEGORIA VALUES (1, 'Herramienta manual', 25);
INSERT INTO CATEGORIA VALUES (2, 'Herramienta electrica', 18);
INSERT INTO CATEGORIA VALUES (3, 'Material electrico', 30);
INSERT INTO CATEGORIA VALUES (4, 'Ferreteria general', 35);
INSERT INTO CATEGORIA VALUES (5, 'Seguridad industrial', 22);

--------------------------------------------------------------------------------
-- BODEGAS
--------------------------------------------------------------------------------
INSERT INTO BODEGA VALUES (1, 'Bodega Central',     'Bogota',       'S');
INSERT INTO BODEGA VALUES (2, 'Bodega Norte',       'Bogota',       'S');
INSERT INTO BODEGA VALUES (3, 'Bodega Antioquia',   'Medellin',     'S');
INSERT INTO BODEGA VALUES (4, 'Bodega Valle',       'Cali',         'S');
INSERT INTO BODEGA VALUES (5, 'Bodega Santander',   'Bucaramanga',  'N');

--------------------------------------------------------------------------------
-- PRODUCTOS
--------------------------------------------------------------------------------
INSERT INTO PRODUCTO VALUES (1001, 'HM-0001', 'Martillo carpintero 16oz',      1,   45000,  28000,  20, 'S');
INSERT INTO PRODUCTO VALUES (1002, 'HM-0002', 'Juego destornilladores 6 pzas', 1,   62000,  38000,  15, 'S');
INSERT INTO PRODUCTO VALUES (1003, 'HM-0003', 'Llave ajustable 10 pulgadas',   1,   38000,  24000,  25, 'S');
INSERT INTO PRODUCTO VALUES (1004, 'HE-0001', 'Taladro percutor 650W',         2,  320000, 245000,  10, 'S');
INSERT INTO PRODUCTO VALUES (1005, 'HE-0002', 'Pulidora angular 4.5 pulgadas', 2,  285000, 215000,   8, 'S');
INSERT INTO PRODUCTO VALUES (1006, 'HE-0003', 'Sierra circular 7.25 pulgadas', 2,  480000, 372000,   5, 'S');
INSERT INTO PRODUCTO VALUES (1007, 'ME-0001', 'Cable THHN 12 AWG metro',       3,    3200,   2100, 500, 'S');
INSERT INTO PRODUCTO VALUES (1008, 'ME-0002', 'Breaker 20A monopolar',         3,   18500,  11800,  40, 'S');
INSERT INTO PRODUCTO VALUES (1009, 'ME-0003', 'Toma corriente doble',          3,    9800,   6200,  60, 'S');
INSERT INTO PRODUCTO VALUES (1010, 'FG-0001', 'Tornillo autoperforante caja',  4,   24000,  15000,  30, 'S');
INSERT INTO PRODUCTO VALUES (1011, 'FG-0002', 'Cinta metrica 8 metros',        4,   29000,  18500,  25, 'S');
INSERT INTO PRODUCTO VALUES (1012, 'SI-0001', 'Casco seguridad dielectrico',   5,   42000,  26000,  20, 'S');
INSERT INTO PRODUCTO VALUES (1013, 'SI-0002', 'Guantes carnaza par',           5,   14500,   8900,  50, 'S');
INSERT INTO PRODUCTO VALUES (1014, 'SI-0003', 'Gafas proteccion',              5,    9500,   5400,  45, 'S');
INSERT INTO PRODUCTO VALUES (1015, 'HM-0004', 'Alicate universal 8 pulgadas',  1,   33000,  20000,  20, 'N');

--------------------------------------------------------------------------------
-- EXISTENCIAS POR BODEGA
--------------------------------------------------------------------------------
INSERT INTO EXISTENCIA VALUES (1, 1001, 120);
INSERT INTO EXISTENCIA VALUES (1, 1002,  80);
INSERT INTO EXISTENCIA VALUES (1, 1003,  12);
INSERT INTO EXISTENCIA VALUES (1, 1004,  35);
INSERT INTO EXISTENCIA VALUES (1, 1005,   4);
INSERT INTO EXISTENCIA VALUES (1, 1006,  18);
INSERT INTO EXISTENCIA VALUES (1, 1007, 320);
INSERT INTO EXISTENCIA VALUES (1, 1008,  95);
INSERT INTO EXISTENCIA VALUES (1, 1009, 140);
INSERT INTO EXISTENCIA VALUES (1, 1010,  70);
INSERT INTO EXISTENCIA VALUES (1, 1011,   9);
INSERT INTO EXISTENCIA VALUES (1, 1012,  55);
INSERT INTO EXISTENCIA VALUES (1, 1013, 210);
INSERT INTO EXISTENCIA VALUES (1, 1014,  38);

INSERT INTO EXISTENCIA VALUES (2, 1001,  40);
INSERT INTO EXISTENCIA VALUES (2, 1004,  12);
INSERT INTO EXISTENCIA VALUES (2, 1007, 150);
INSERT INTO EXISTENCIA VALUES (2, 1008,  30);
INSERT INTO EXISTENCIA VALUES (2, 1013,  75);

INSERT INTO EXISTENCIA VALUES (3, 1002,  25);
INSERT INTO EXISTENCIA VALUES (3, 1005,  10);
INSERT INTO EXISTENCIA VALUES (3, 1009,  60);
INSERT INTO EXISTENCIA VALUES (3, 1012,  22);

INSERT INTO EXISTENCIA VALUES (4, 1003,  45);
INSERT INTO EXISTENCIA VALUES (4, 1006,   6);
INSERT INTO EXISTENCIA VALUES (4, 1010,  33);
INSERT INTO EXISTENCIA VALUES (4, 1014,  28);

--------------------------------------------------------------------------------
-- CLIENTES
--------------------------------------------------------------------------------
INSERT INTO CLIENTE VALUES (501, '900123456', 'Constructora Andes SAS',    'Bogota',       8000000, 1250000, 'S');
INSERT INTO CLIENTE VALUES (502, '900234567', 'Electricos del Norte Ltda', 'Bogota',       5000000, 4700000, 'S');
INSERT INTO CLIENTE VALUES (503, '900345678', 'Ferreteria La Esquina',     'Medellin',     2000000,       0, 'S');
INSERT INTO CLIENTE VALUES (504, '900456789', 'Obras Civiles del Valle',   'Cali',        12000000, 3400000, 'S');
INSERT INTO CLIENTE VALUES (505, '900567890', 'Mantenimientos Tecnicos',   'Bogota',       1500000, 1500000, 'S');
INSERT INTO CLIENTE VALUES (506, '900678901', 'Suministros del Caribe SA', 'Barranquilla', 3000000,       0, 'N');
INSERT INTO CLIENTE VALUES (507, '900789012', 'Distribuidora Caribe',      'Barranquilla', 6000000,  800000, 'S');

--------------------------------------------------------------------------------
-- PEDIDOS
--------------------------------------------------------------------------------
INSERT INTO PEDIDO VALUES (1, 501, TO_DATE('2026-06-10','YYYY-MM-DD'), 'CONFIRMADO', 1286500);
INSERT INTO PEDIDO VALUES (2, 501, TO_DATE('2026-07-02','YYYY-MM-DD'), 'CONFIRMADO',  641000);
INSERT INTO PEDIDO VALUES (3, 502, TO_DATE('2026-07-15','YYYY-MM-DD'), 'CONFIRMADO',  923000);
INSERT INTO PEDIDO VALUES (4, 503, TO_DATE('2026-08-01','YYYY-MM-DD'), 'CONFIRMADO',  332000);
INSERT INTO PEDIDO VALUES (5, 504, TO_DATE('2026-08-20','YYYY-MM-DD'), 'CONFIRMADO', 2540000);
INSERT INTO PEDIDO VALUES (6, 501, TO_DATE('2026-09-05','YYYY-MM-DD'), 'BORRADOR',         0);
INSERT INTO PEDIDO VALUES (7, 507, TO_DATE('2026-09-12','YYYY-MM-DD'), 'ANULADO',     332500);

INSERT INTO DETALLE_PEDIDO VALUES (1, 1, 1004, 1,   3, 320000,  960000);
INSERT INTO DETALLE_PEDIDO VALUES (1, 2, 1001, 1,   5,  45000,  225000);
INSERT INTO DETALLE_PEDIDO VALUES (1, 3, 1013, 1,   7,  14500,  101500);
INSERT INTO DETALLE_PEDIDO VALUES (2, 1, 1002, 1,   8,  62000,  496000);
INSERT INTO DETALLE_PEDIDO VALUES (2, 2, 1011, 1,   5,  29000,  145000);
INSERT INTO DETALLE_PEDIDO VALUES (3, 1, 1007, 2, 200,   3200,  640000);
INSERT INTO DETALLE_PEDIDO VALUES (3, 2, 1008, 2,  10,  18500,  185000);
INSERT INTO DETALLE_PEDIDO VALUES (3, 3, 1009, 2,  10,   9800,   98000);
INSERT INTO DETALLE_PEDIDO VALUES (4, 1, 1002, 3,   4,  62000,  248000);
INSERT INTO DETALLE_PEDIDO VALUES (4, 2, 1012, 3,   2,  42000,   84000);
INSERT INTO DETALLE_PEDIDO VALUES (5, 1, 1006, 4,   4, 480000, 1920000);
INSERT INTO DETALLE_PEDIDO VALUES (5, 2, 1003, 4,  10,  38000,  380000);
INSERT INTO DETALLE_PEDIDO VALUES (5, 3, 1010, 4,  10,  24000,  240000);
INSERT INTO DETALLE_PEDIDO VALUES (7, 1, 1005, 1,   1, 285000,  285000);
INSERT INTO DETALLE_PEDIDO VALUES (7, 2, 1014, 1,   5,   9500,   47500);

--------------------------------------------------------------------------------
-- BITACORA DE MOVIMIENTOS
--------------------------------------------------------------------------------
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 1, 1001, 1, 'ENTRADA', 150, TO_DATE('2026-05-02','YYYY-MM-DD'), NULL, 'Compra a proveedor');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 2, 1002, 1, 'ENTRADA', 100, TO_DATE('2026-05-02','YYYY-MM-DD'), NULL, 'Compra a proveedor');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 3, 1004, 1, 'ENTRADA',  40, TO_DATE('2026-05-15','YYYY-MM-DD'), NULL, 'Compra a proveedor');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 4, 1007, 2, 'ENTRADA', 500, TO_DATE('2026-06-01','YYYY-MM-DD'), NULL, 'Compra a proveedor');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 5, 1004, 1, 'SALIDA',    3, TO_DATE('2026-06-10','YYYY-MM-DD'),    1, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 6, 1001, 1, 'SALIDA',    5, TO_DATE('2026-06-10','YYYY-MM-DD'),    1, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 7, 1013, 1, 'SALIDA',    7, TO_DATE('2026-06-10','YYYY-MM-DD'),    1, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 8, 1001, 2, 'ENTRADA',  40, TO_DATE('2026-06-20','YYYY-MM-DD'), NULL, 'Traslado entre bodegas');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES ( 9, 1002, 1, 'SALIDA',    8, TO_DATE('2026-07-02','YYYY-MM-DD'),    2, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (10, 1011, 1, 'SALIDA',    5, TO_DATE('2026-07-02','YYYY-MM-DD'),    2, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (11, 1003, 4, 'ENTRADA',  60, TO_DATE('2026-07-10','YYYY-MM-DD'), NULL, 'Compra a proveedor');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (12, 1007, 2, 'SALIDA',  200, TO_DATE('2026-07-15','YYYY-MM-DD'),    3, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (13, 1008, 2, 'SALIDA',   10, TO_DATE('2026-07-15','YYYY-MM-DD'),    3, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (14, 1009, 2, 'SALIDA',   10, TO_DATE('2026-07-15','YYYY-MM-DD'),    3, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (15, 1002, 3, 'SALIDA',    4, TO_DATE('2026-08-01','YYYY-MM-DD'),    4, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (16, 1012, 3, 'SALIDA',    2, TO_DATE('2026-08-01','YYYY-MM-DD'),    4, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (17, 1006, 4, 'SALIDA',    4, TO_DATE('2026-08-20','YYYY-MM-DD'),    5, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (18, 1003, 4, 'SALIDA',   10, TO_DATE('2026-08-20','YYYY-MM-DD'),    5, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (19, 1010, 4, 'SALIDA',   10, TO_DATE('2026-08-20','YYYY-MM-DD'),    5, 'Despacho de pedido');
INSERT INTO MOVIMIENTO_INVENTARIO (id_movimiento, id_producto, id_bodega, tipo, cantidad, fecha_mov, id_pedido, observacion)
VALUES (20, 1001, 1, 'AJUSTE',   25, TO_DATE('2026-08-25','YYYY-MM-DD'), NULL, 'Conteo fisico');

--------------------------------------------------------------------------------
-- SINCRONIZACION DE SECUENCIAS CON LOS DATOS CARGADOS
--------------------------------------------------------------------------------
DECLARE
  v_max NUMBER;
  v_val NUMBER;
BEGIN
  SELECT MAX(id_pedido) INTO v_max FROM PEDIDO;
  FOR i IN 1 .. v_max LOOP
    SELECT SEQ_PEDIDO.NEXTVAL INTO v_val FROM DUAL;
  END LOOP;

  SELECT MAX(id_movimiento) INTO v_max FROM MOVIMIENTO_INVENTARIO;
  FOR i IN 1 .. v_max LOOP
    SELECT SEQ_MOVIMIENTO.NEXTVAL INTO v_val FROM DUAL;
  END LOOP;
END;
/

COMMIT;

--------------------------------------------------------------------------------
-- VERIFICACION DE LA CARGA
--------------------------------------------------------------------------------
DECLARE
  v_n NUMBER;
  PROCEDURE p(p_texto VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE(p_texto); END;
BEGIN
  p('=====================================================');
  p('  ESQUEMA DEL TALLER PL/SQL CREADO CORRECTAMENTE');
  p('=====================================================');
  SELECT COUNT(*) INTO v_n FROM CATEGORIA;              p('  Categorias ............... ' || v_n);
  SELECT COUNT(*) INTO v_n FROM BODEGA;                 p('  Bodegas .................. ' || v_n);
  SELECT COUNT(*) INTO v_n FROM PRODUCTO;               p('  Productos ................ ' || v_n);
  SELECT COUNT(*) INTO v_n FROM CLIENTE;                p('  Clientes ................. ' || v_n);
  SELECT COUNT(*) INTO v_n FROM EXISTENCIA;             p('  Existencias .............. ' || v_n);
  SELECT COUNT(*) INTO v_n FROM PEDIDO;                 p('  Pedidos .................. ' || v_n);
  SELECT COUNT(*) INTO v_n FROM DETALLE_PEDIDO;         p('  Detalles de pedido ....... ' || v_n);
  SELECT COUNT(*) INTO v_n FROM MOVIMIENTO_INVENTARIO;  p('  Movimientos .............. ' || v_n);
  p('-----------------------------------------------------');
  p('  Si estas cifras coinciden con las del enunciado,');
  p('  puede continuar con 02_plantilla_entregable.sql');
  p('=====================================================');
END;
/

    