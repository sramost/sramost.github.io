-- Oracle: dos sesiones reales, autocommit apagado. Ejecutar por pasos, no todo de corrido.
-- Preparación A:
CREATE TABLE lab_bd2_saldo(id NUMBER PRIMARY KEY,saldo NUMBER NOT NULL);
INSERT INTO lab_bd2_saldo VALUES(1,1000);
COMMIT;
-- A1 y B1: ambos leen 1000.
SELECT saldo FROM lab_bd2_saldo WHERE id=1;
-- A2:
UPDATE lab_bd2_saldo SET saldo=700 WHERE id=1;
-- B2: en B, espera hasta A3.
UPDATE lab_bd2_saldo SET saldo=800 WHERE id=1;
-- A3: confirmar en A y luego B3: confirmar en B.
COMMIT;
-- Esperado: 800 en lugar de 500. El valor de B fue calculado con una lectura antigua.
SELECT saldo FROM lab_bd2_saldo WHERE id=1;
-- A: reiniciar.
UPDATE lab_bd2_saldo SET saldo=1000 WHERE id=1;
COMMIT;
-- A4: ejecutar en A y dejar sin confirmar.
UPDATE lab_bd2_saldo SET saldo=saldo-300 WHERE id=1;
-- B4: ejecutar en B, espera a A5.
UPDATE lab_bd2_saldo SET saldo=saldo-200 WHERE id=1;
-- A5 y B5: confirmar primero A, después B.
COMMIT;
SELECT saldo FROM lab_bd2_saldo WHERE id=1;
-- Esperado 500. Para flujos de lectura y decisión usar SELECT FOR UPDATE.
-- Limpieza en A después de finalizar ambas transacciones:
DROP TABLE lab_bd2_saldo PURGE;
