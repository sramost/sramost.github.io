-- Ejecutar en esquema desechable Oracle, nombres reservados para este laboratorio.
CREATE TABLE lab_bd2_ix (id NUMBER PRIMARY KEY, nombre VARCHAR2(80));
INSERT INTO lab_bd2_ix SELECT LEVEL,'cliente '||LEVEL FROM dual CONNECT BY LEVEL<=50000;
COMMIT;
CREATE INDEX ix_lab_nombre ON lab_bd2_ix(nombre);
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'LAB_BD2_IX',cascade=>TRUE);
EXPLAIN PLAN SET STATEMENT_ID='LAB_ANTES' FOR SELECT id FROM lab_bd2_ix WHERE UPPER(nombre)='CLIENTE 123';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','LAB_ANTES','BASIC +COST +PREDICATE'));
CREATE INDEX ix_lab_upper ON lab_bd2_ix(UPPER(nombre));
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER,'LAB_BD2_IX',cascade=>TRUE);
EXPLAIN PLAN SET STATEMENT_ID='LAB_DESPUES' FOR SELECT id FROM lab_bd2_ix WHERE UPPER(nombre)='CLIENTE 123';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE','LAB_DESPUES','BASIC +COST +PREDICATE'));
-- Hipótesis: acceso selectivo por índice funcional; el optimizador decide según estadísticas.
-- Comparar coste y plan. No equivale a tiempo medido.
DROP TABLE lab_bd2_ix PURGE;
