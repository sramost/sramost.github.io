-- Objetivo: comprobar por qué NOT IN falla con NULL.
WITH candidatos AS (SELECT 1 id FROM dual UNION ALL SELECT 2 FROM dual),
 excluidos AS (SELECT 1 id FROM dual UNION ALL SELECT CAST(NULL AS NUMBER) FROM dual)
SELECT id FROM candidatos WHERE id NOT IN (SELECT id FROM excluidos);
-- Esperado: ninguna fila.
WITH candidatos AS (SELECT 1 id FROM dual UNION ALL SELECT 2 FROM dual),
 excluidos AS (SELECT 1 id FROM dual UNION ALL SELECT CAST(NULL AS NUMBER) FROM dual)
SELECT c.id FROM candidatos c WHERE NOT EXISTS (SELECT 1 FROM excluidos e WHERE e.id=c.id);
-- Esperado: 2. UNKNOWN no satisface WHERE; EXISTS comprueba existencia.
