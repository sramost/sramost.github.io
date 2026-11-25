SET SERVEROUTPUT ON
DECLARE
 e_regla EXCEPTION;
BEGIN
 BEGIN
  RAISE e_regla;
 EXCEPTION WHEN e_regla THEN
  DBMS_OUTPUT.PUT_LINE('Interno: registra y relanza');
  RAISE;
 END;
EXCEPTION WHEN e_regla THEN
 DBMS_OUTPUT.PUT_LINE('Externo: maneja la excepción');
END;
/
-- Esperado: ambos mensajes, en ese orden. Sin RAISE el error no llega al bloque externo.
