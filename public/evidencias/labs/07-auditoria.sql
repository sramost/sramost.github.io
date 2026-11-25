CREATE TABLE lab_bd2_prod(id NUMBER PRIMARY KEY,precio NUMBER);
CREATE TABLE lab_bd2_aud(id NUMBER,anterior NUMBER,nuevo NUMBER);
INSERT INTO lab_bd2_prod VALUES(1,100);
COMMIT;
CREATE OR REPLACE TRIGGER TGR_AU_LAB_BD2
AFTER UPDATE OF precio ON lab_bd2_prod FOR EACH ROW
BEGIN
 INSERT INTO lab_bd2_aud VALUES(:OLD.id,:OLD.precio,:NEW.precio);
END;
/
UPDATE lab_bd2_prod SET precio=120 WHERE id=1;
SELECT * FROM lab_bd2_aud; -- esperado 1,100,120
ROLLBACK;
SELECT * FROM lab_bd2_aud; -- esperado ninguna fila
SELECT * FROM lab_bd2_prod; -- esperado 1,100
DROP TABLE lab_bd2_prod PURGE;
DROP TABLE lab_bd2_aud PURGE;
-- La auditoría transaccional se revierte junto con el cambio.
