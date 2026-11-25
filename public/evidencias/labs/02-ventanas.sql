-- Objetivo: distinguir rango lógico y posición física.
WITH datos AS (SELECT 1 id, 10 monto FROM dual UNION ALL SELECT 2,10 FROM dual UNION ALL SELECT 3,5 FROM dual)
SELECT id,monto,ROW_NUMBER() OVER(ORDER BY monto DESC,id) rn,
RANK() OVER(ORDER BY monto DESC) rk,DENSE_RANK() OVER(ORDER BY monto DESC) dr,
SUM(monto) OVER(ORDER BY monto DESC) acum_range,
SUM(monto) OVER(ORDER BY monto DESC,id ROWS UNBOUNDED PRECEDING) acum_rows
FROM datos ORDER BY monto DESC,id;
-- Esperado: rk 1,1,3; dr 1,1,2; RANGE 20,20,25; ROWS 10,20,25.
