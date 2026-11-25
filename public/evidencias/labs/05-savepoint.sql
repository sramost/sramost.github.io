CREATE TABLE lab_bd2_tx(id NUMBER PRIMARY KEY, saldo NUMBER);
INSERT INTO lab_bd2_tx VALUES(1,100);
COMMIT;
UPDATE lab_bd2_tx SET saldo=90 WHERE id=1;
SAVEPOINT ajuste;
UPDATE lab_bd2_tx SET saldo=0 WHERE id=1;
ROLLBACK TO ajuste;
SELECT saldo FROM lab_bd2_tx; -- esperado 90
ROLLBACK;
SELECT saldo FROM lab_bd2_tx; -- esperado 100
DROP TABLE lab_bd2_tx PURGE;
-- SAVEPOINT revierte una parte; ROLLBACK completo revierte lo no confirmado.
