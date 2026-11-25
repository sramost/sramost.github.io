-- Corrección posterior del Quiz 2. Fuente: guía de revisión AeroAndes.
-- P1: eliminar num_vuelo no agrupado; evitar ROWNUM prematuro, NOT IN con NULL,
-- multiplicación de reservas por incidencias y reservas anuladas.
WITH ingresos AS (
 SELECT v.cod_origen||'-'||v.cod_destino ruta,SUM(r.tarifa) ingreso
 FROM vuelo v JOIN reserva r ON r.id_vuelo=v.id_vuelo
 WHERE v.fecha_salida>=DATE '2026-01-01' AND r.estado<>'ANULADA'
 AND NOT EXISTS(SELECT 1 FROM pasajero p WHERE p.id_pasajero_referido=r.id_pasajero)
 GROUP BY v.cod_origen,v.cod_destino
), incidentes AS (
 SELECT v.cod_origen||'-'||v.cod_destino ruta,COUNT(DISTINCT i.id_vuelo) vuelos_con_incidencia
 FROM vuelo v JOIN incidencia i ON i.id_vuelo=v.id_vuelo
 WHERE v.fecha_salida>=DATE '2026-01-01' GROUP BY v.cod_origen,v.cod_destino
), ranking AS (
 SELECT g.ruta,g.ingreso,NVL(x.vuelos_con_incidencia,0) vuelos_con_incidencia,
 RANK() OVER(ORDER BY g.ingreso DESC) puesto
 FROM ingresos g LEFT JOIN incidentes x ON x.ruta=g.ruta
)
SELECT * FROM ranking WHERE puesto<=5 ORDER BY puesto,ruta;
-- P2a: ranking mensual con desempate por ruta.
WITH mensual AS (
 SELECT TRUNC(v.fecha_salida,'MM') mes,v.cod_origen||'-'||v.cod_destino ruta,SUM(r.tarifa) ingreso
 FROM vuelo v JOIN reserva r ON r.id_vuelo=v.id_vuelo
 WHERE v.fecha_salida>=DATE '2026-01-01' AND v.fecha_salida<DATE '2027-01-01' AND r.estado<>'ANULADA'
 GROUP BY TRUNC(v.fecha_salida,'MM'),v.cod_origen,v.cod_destino
), ordenado AS (
 SELECT mensual.*,RANK() OVER(PARTITION BY mes ORDER BY ingreso DESC,ruta) puesto FROM mensual
)
SELECT * FROM ordenado WHERE puesto<=3 ORDER BY mes,puesto;
-- P2b: RANGE agrupa pares; ROWS con identificador único acumula fila a fila.
SELECT r.id_reserva,r.fecha_compra,r.tarifa,
 SUM(r.tarifa) OVER(PARTITION BY v.cod_origen ORDER BY r.fecha_compra) acum_range,
 SUM(r.tarifa) OVER(PARTITION BY v.cod_origen ORDER BY r.fecha_compra,r.id_reserva ROWS UNBOUNDED PRECEDING) acum_rows
FROM reserva r JOIN vuelo v ON v.id_vuelo=r.id_vuelo
WHERE v.cod_origen='BOG' AND r.fecha_compra=DATE '2026-01-08' ORDER BY r.id_reserva;
-- P2c: caída superior al 30%; LAG compara observaciones existentes.
WITH mensual AS (
 SELECT TRUNC(v.fecha_salida,'MM') mes,v.cod_origen||'-'||v.cod_destino ruta,SUM(r.tarifa) ingreso
 FROM vuelo v JOIN reserva r ON r.id_vuelo=v.id_vuelo
 WHERE v.fecha_salida>=DATE '2026-01-01' AND v.fecha_salida<DATE '2027-01-01' AND r.estado<>'ANULADA'
 GROUP BY TRUNC(v.fecha_salida,'MM'),v.cod_origen,v.cod_destino
), comparado AS (
 SELECT mensual.*,LAG(ingreso) OVER(PARTITION BY ruta ORDER BY mes) anterior,
 LAG(mes) OVER(PARTITION BY ruta ORDER BY mes) mes_anterior FROM mensual
)
SELECT ruta,mes,ingreso,anterior,ROUND(100*(ingreso-anterior)/NULLIF(anterior,0),2) variacion_pct
FROM comparado WHERE anterior>0 AND ingreso<anterior*0.7
-- Para exigir mes calendario anterior, descomentar:
-- AND mes_anterior=ADD_MONTHS(mes,-1)
ORDER BY ruta,mes;
