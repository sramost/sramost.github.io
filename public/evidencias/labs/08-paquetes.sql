SET SERVEROUTPUT ON
CREATE OR REPLACE PACKAGE PCK_LAB_BD2 IS
 FUNCTION fn_siguiente RETURN NUMBER;
END;
/
CREATE OR REPLACE PACKAGE BODY PCK_LAB_BD2 IS
 v_contador NUMBER:=0;
 FUNCTION fn_siguiente RETURN NUMBER IS
 BEGIN
  v_contador:=v_contador+1;
  RETURN v_contador;
 END;
END;
/
BEGIN
 DBMS_OUTPUT.PUT_LINE(PCK_LAB_BD2.fn_siguiente);
 DBMS_OUTPUT.PUT_LINE(PCK_LAB_BD2.fn_siguiente);
END;
/
-- Esperado 1,2 en sesión nueva; en una segunda sesión vuelve a iniciar.
-- ROLLBACK no revierte una variable PL/SQL de paquete.
-- Limpiar tras terminar ambas sesiones:
DROP PACKAGE PCK_LAB_BD2;
