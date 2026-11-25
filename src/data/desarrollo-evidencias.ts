export type Desarrollo = {titulo:string; desde:number; hasta:number; explicacion:string; comprobacion:string};
export const desarrollo: Record<string, Desarrollo[]> = {
  "repaso-hr": [
    {
      "titulo": "6.1 · Casos borde",
      "desde": 2,
      "hasta": 6,
      "explicacion": "Se construyen cuatro conteos independientes unidos con UNION ALL. IS NULL comprueba la ausencia de jefe, departamento y comisión; NOT EXISTS identifica departamentos sin empleados. El último conteo mide departamentos, no empleados.",
      "comprobacion": "Cada rama debe producir una fila; comprobar los cuatro conteos por separado."
    },
    {
      "titulo": "6.2 · Inventario de departamentos",
      "desde": 7,
      "hasta": 10,
      "explicacion": "La consulta parte de departments y mantiene las filas sin empleados mediante LEFT JOIN. Las relaciones con locations y countries añaden ubicación. COUNT(e.employee_id) cuenta empleados reales, mientras AVG ignora nulos.",
      "comprobacion": "Un departamento vacío debe tener employee_count = 0 y avg_salary nulo."
    },
    {
      "titulo": "6.3 · Cadena de mando",
      "desde": 11,
      "hasta": 14,
      "explicacion": "El self join usa dos alias de employees: e representa al subordinado y m al jefe. CASE evita presentar un espacio como nombre de un jefe inexistente. El join con jobs recupera el cargo.",
      "comprobacion": "El empleado 100 debe conservarse aunque no tenga jefe."
    },
    {
      "titulo": "6.4 · ON frente a WHERE",
      "desde": 15,
      "hasta": 17,
      "explicacion": "El filtro en ON condiciona las coincidencias de la derecha sin eliminar departamentos. En WHERE se evalúa después de la reunión y descarta salarios nulos o inferiores al umbral.",
      "comprobacion": "Comparar ambos conteos y buscar un departamento sin empleados con salario superior a 10000."
    },
    {
      "titulo": "6.5 · Jefes, comisiones y nulos",
      "desde": 18,
      "hasta": 21,
      "explicacion": "NVL transforma una comisión ausente en cero para calcular la compensación. NOT EXISTS comprueba si no existe un subordinado. NOT IN puede devolver UNKNOWN cuando su subconsulta contiene NULL.",
      "comprobacion": "Un empleado sin subordinados debe recibir NO; verificar que manager_id contiene nulos antes de comparar NOT IN."
    },
    {
      "titulo": "6.6 · Agregación condicional",
      "desde": 22,
      "hasta": 25,
      "explicacion": "GROUP BY construye una fila por departamento; HAVING exige más de cinco empleados y promedio superior a 6000. COUNT(CASE...) cuenta únicamente contrataciones posteriores a la fecha sin eliminar otros empleados de la nómina.",
      "comprobacion": "Cada grupo devuelto debe satisfacer ambos filtros y empleados_recientes no puede superar employee_count."
    },
    {
      "titulo": "6.7 · Comparación con el promedio departamental",
      "desde": 26,
      "hasta": 32,
      "explicacion": "La versión correlacionada calcula el promedio según el departamento de cada empleado; la CTE lo calcula por grupo y lo reúne después. NULLIF protege la división por cero. Ambas expresan la misma comparación bajo el tratamiento de departamentos nulos elegido.",
      "comprobacion": "Comparar filas y columnas de ambas versiones; usar AUTOTRACE o EXPLAIN PLAN para observar el plan, sin inferir rendimiento a partir de la sintaxis."
    },
    {
      "titulo": "6.8 · Movilidad laboral",
      "desde": 33,
      "hasta": 38,
      "explicacion": "INTERSECT obtiene empleados con historial y MINUS aquellos sin historial. UNION ALL combina categorías disjuntas. La alternativa NOT EXISTS expresa directamente la ausencia de historial.",
      "comprobacion": "Cada empleado debe quedar en una categoría y no duplicarse."
    },
    {
      "titulo": "6.9 · Jerarquía recursiva",
      "desde": 39,
      "hasta": 44,
      "explicacion": "La rama ancla obtiene los empleados sin jefe; la recursiva añade subordinados, incrementa el nivel y concatena la ruta. CYCLE detecta una repetición del identificador en la rama.",
      "comprobacion": "El jefe raíz debe estar en nivel 1; cada subordinado alcanzable debe tener la ruta de su superior como prefijo."
    },
    {
      "titulo": "6.10 · Funciones analíticas",
      "desde": 45,
      "hasta": 58,
      "explicacion": "PARTITION BY reinicia el cálculo por departamento. RANK deja huecos en empates, DENSE_RANK no y ROW_NUMBER distingue filas. LAG compara con el empleado anterior en orden de contratación; ROWS con employee_id hace determinista el acumulado.",
      "comprobacion": "Buscar salarios empatados y comparar los tres rankings. En el último registro de cada partición, el acumulado debe coincidir con la suma departamental."
    },
    {
      "titulo": "6.11 · Top tres por departamento",
      "desde": 59,
      "hasta": 61,
      "explicacion": "DENSE_RANK preserva empates y se calcula antes de aplicar el filtro externo drk <= 3. Pueden aparecer más de tres empleados si hay salarios empatados.",
      "comprobacion": "Verificar que no aparezca un cuarto salario distinto dentro de un departamento."
    },
    {
      "titulo": "6.12 · Depuración de cinco consultas",
      "desde": 62,
      "hasta": 74,
      "explicacion": "Se corrigen cinco problemas: COUNT(*) sobre reunión externa, exclusión involuntaria de nulos, conteo de empleados en departamentos estadounidenses, máximo salarial por departamento y promedio de comisiones incluyendo ceros.",
      "comprobacion": "Comprobar departamentos vacíos, empleados sin departamento, empates en salario máximo y el efecto de NVL sobre el promedio."
    }
  ],
  "aeroandes": [
    {
      "titulo": "Pregunta 1 · Corrección de la consulta por rutas",
      "desde": 2,
      "hasta": 19,
      "explicacion": "Los cinco defectos son: num_vuelo fuera del GROUP BY, ROWNUM antes del ranking, NOT IN con nulos, multiplicación de tarifas por varias incidencias y reservas anuladas incluidas. Se separan ingresos e incidencias en dos CTE, se reúnen por ruta y se filtra el ranking al final. COUNT(DISTINCT) resuelve el conteo de vuelos, pero por sí solo no corrige la suma inflada.",
      "comprobacion": "Referencia docente: BOG-MDE 15.700.000 (4 incidencias de vuelo), BOG-CTG 14.000.000 (4), BOG-CLO 11.300.000 (3), BOG-BAQ 10.100.000 (4), MDE-CTG 5.100.000 (1)."
    },
    {
      "titulo": "Pregunta 2a · Ranking mensual",
      "desde": 20,
      "hasta": 29,
      "explicacion": "TRUNC(fecha_salida,'MM') conserva el tipo fecha y agrupa por mes. La ventana se particiona por mes y ordena por ingreso descendente y ruta ascendente. El filtro externo selecciona los tres puestos.",
      "comprobacion": "En febrero, las rutas BOG-BAQ y BOG-CTG empatan con 4.000.000; el código de ruta define el orden. Cifras de la guía docente."
    },
    {
      "titulo": "Pregunta 2b · Acumulación fila a fila",
      "desde": 30,
      "hasta": 35,
      "explicacion": "RANGE incluye todos los pares con la misma fecha en la ventana. ROWS incorpora las filas una a una; id_reserva desempata para obtener resultados reproducibles.",
      "comprobacion": "En el ejemplo docente del 8 de enero, el acumulado RANGE es 10.080.000 en las 17 filas; ROWS empieza en 1.000.000 y termina en 10.080.000."
    },
    {
      "titulo": "Pregunta 2c · Caídas mensuales",
      "desde": 36,
      "hasta": 50,
      "explicacion": "La primera CTE calcula ingresos mensuales; LAG obtiene el ingreso y mes anteriores de cada ruta. El porcentaje divide la diferencia por el ingreso anterior, protegido con NULLIF. El filtro opcional ADD_MONTHS exige continuidad de calendario.",
      "comprobacion": "BOG-BAQ en abril cae de 3.600.000 a 1.000.000 (−72,22 %), según la guía. MDE-CTG evidencia que LAG puede comparar abril contra febrero si falta marzo."
    }
  ],
  "banco-andino": [
    {
      "titulo": "1.1 · Actualización perdida",
      "desde": 11,
      "hasta": 39,
      "explicacion": "Dos sesiones calculan retiros a partir del mismo saldo inicial y escriben valores absolutos. Aunque Oracle serializa las escrituras, la segunda puede sobrescribir el cálculo de la primera.",
      "comprobacion": "Saldo inicial 1.000.000; retiros 300.000 y 200.000; saldo incorrecto 800.000 frente a 500.000 esperado."
    },
    {
      "titulo": "1.2 · Bloqueo pesimista",
      "desde": 40,
      "hasta": 62,
      "explicacion": "SELECT FOR UPDATE bloquea la fila antes de calcular el retiro. La sesión competidora debe esperar a que la primera confirme o revierta; después obtiene el saldo vigente.",
      "comprobacion": "El saldo final esperado es 500.000. Ejecutar cada sesión por separado."
    },
    {
      "titulo": "1.3 · Bloqueo optimista",
      "desde": 63,
      "hasta": 93,
      "explicacion": "La columna de versión permite actualizar únicamente si el registro conserva la versión leída. Si SQL%ROWCOUNT es cero, el cliente debe detectar el conflicto y repetir el cálculo con datos actuales.",
      "comprobacion": "La segunda escritura con versión antigua no debe sobrescribir la primera."
    },
    {
      "titulo": "1.4 · Reparto de tareas con SKIP LOCKED",
      "desde": 94,
      "hasta": 132,
      "explicacion": "Cada consumidor adquiere filas disponibles y omite las ya bloqueadas. Se deben procesar exactamente los identificadores obtenidos por el cursor; los IDs fijos del ejemplo requieren adaptación.",
      "comprobacion": "En dos sesiones, comprobar que las tareas asignadas no se solapen y que las pendientes puedan retomarse."
    },
    {
      "titulo": "1.5 · Llave foránea sin índice",
      "desde": 133,
      "hasta": 162,
      "explicacion": "Una FK sin índice puede incrementar el alcance de bloqueos cuando se modifica o elimina una clave padre. El índice facilita localizar referencias hijas.",
      "comprobacion": "Comparar el comportamiento concurrente antes y después del índice; no confundir un bloqueo con una violación de integridad."
    },
    {
      "titulo": "1.6 · Interbloqueo",
      "desde": 163,
      "hasta": 196,
      "explicacion": "Dos sesiones adquieren cuentas en orden inverso y luego solicitan la fila que posee la otra. Oracle detecta el ciclo y devuelve ORA-00060 a una sentencia.",
      "comprobacion": "Revertir la transacción afectada según corresponda; prevenir el ciclo adquiriendo recursos en orden consistente."
    },
    {
      "titulo": "2.1 · Informe de la Superintendencia",
      "desde": 205,
      "hasta": 267,
      "explicacion": "Se compara el plan del informe sin índice y con índices compuestos. La posición de las columnas importa porque el acceso combina filtros de igualdad y rango.",
      "comprobacion": "Anotaciones originales: costo 377 sin índice y 39 con uno de los índices; el otro orden se compara en el script. El costo es una estimación del optimizador."
    },
    {
      "titulo": "2.2 · Función en el predicado",
      "desde": 268,
      "hasta": 315,
      "explicacion": "UPPER aplicado a una columna puede impedir un acceso eficiente mediante un índice ordinario. Un índice funcional cubre la expresión; una fecha filtrada por TRUNC puede reescribirse mediante un intervalo semiabierto.",
      "comprobacion": "Costos registrados: 49 a 2 para UPPER y 238 a 4 para la reescritura de fecha."
    },
    {
      "titulo": "2.3 · Cuándo no conviene un índice",
      "desde": 316,
      "hasta": 344,
      "explicacion": "La selectividad determina qué fracción de filas se recupera. Si el filtro devuelve una gran parte de la tabla, leerla secuencialmente puede costar menos que visitar muchos bloques mediante un índice.",
      "comprobacion": "Comparar cardinalidad y plan; no concluir que todo TABLE ACCESS FULL es un error."
    },
    {
      "titulo": "2.4 · Índice de cobertura",
      "desde": 345,
      "hasta": 373,
      "explicacion": "Si un índice contiene las columnas necesarias para el filtro y la proyección, Oracle puede responder sin consultar los bloques de la tabla.",
      "comprobacion": "El script registra la comparación de costo 378 frente a 92. Verificar si desaparece el acceso a tabla."
    },
    {
      "titulo": "2.5 · Costo de escritura",
      "desde": 374,
      "hasta": 416,
      "explicacion": "Cada inserción o actualización de una columna indexada exige mantener estructuras adicionales. El diseño final debe equilibrar reportes y transacciones.",
      "comprobacion": "Medición consignada por el grupo: 2,092 s frente a 0,479 s para 50.000 inserciones en los escenarios evaluados."
    },
    {
      "titulo": "3.1 · Ranking por familia",
      "desde": 421,
      "hasta": 512,
      "explicacion": "Los rankings globales y por familia responden preguntas distintas. Se agregan saldos o cantidades por producto y se calcula la posición dentro de la familia, conservando el denominador para el porcentaje.",
      "comprobacion": "Revisar empates y verificar que el porcentaje utilice el total de la familia, no el del top tres."
    },
    {
      "titulo": "3.2 · Evolución mensual",
      "desde": 513,
      "hasta": 557,
      "explicacion": "Una vez agregadas las operaciones por mes, SUM OVER calcula el acumulado, LAG recupera el valor previo y AVG con un marco móvil suaviza las variaciones.",
      "comprobacion": "Comparar ROWS y RANGE con empates; verificar que la ventana móvil tenga el tamaño solicitado."
    },
    {
      "titulo": "3.3 · Jerarquía de productos",
      "desde": 558,
      "hasta": 593,
      "explicacion": "La CTE recursiva y CONNECT BY representan dos alternativas Oracle para recorrer relaciones padre-hijo y asociar saldos con líneas de negocio.",
      "comprobacion": "Comparar los totales de ambas versiones y revisar la dirección de la relación jerárquica."
    },
    {
      "titulo": "3.4 · Ajustes con MERGE",
      "desde": 594,
      "hasta": 643,
      "explicacion": "MERGE combina la coincidencia con la cuenta y la acción de ajuste. Las reglas de saldo se evalúan para evitar aplicar cargos que incumplan las condiciones.",
      "comprobacion": "El caso de prueba usa la cuenta 1001 con una cuota superior al saldo; revisar el estado y el registro del ajuste."
    },
    {
      "titulo": "3.5 · Clientes sin transferencias",
      "desde": 644,
      "hasta": 695,
      "explicacion": "Una antiunión permite conservar clientes preferenciales sin operaciones en el intervalo de 120 días. NOT EXISTS evita depender de la nulabilidad de una subconsulta.",
      "comprobacion": "Contrastar con el historial y verificar que ningún cliente devuelto tenga transferencias dentro de la ventana exigida."
    },
    {
      "titulo": "4A · Diagnóstico del reto integrador",
      "desde": 696,
      "hasta": 810,
      "explicacion": "Se analiza una secuencia de operaciones financieras que puede producir inconsistencias bajo concurrencia y se identifican problemas de acceso a datos.",
      "comprobacion": "Inspeccionar las lecturas, escrituras y confirmaciones de ambas sesiones antes de ejecutar la secuencia."
    },
    {
      "titulo": "4B · Secuencia corregida",
      "desde": 811,
      "hasta": 915,
      "explicacion": "Se reorganiza la transferencia para mantener el orden de bloqueo y la atomicidad. La confirmación corresponde al conjunto de operaciones de negocio, no a cada modificación aislada.",
      "comprobacion": "Comprobar saldos origen/destino y que una operación fallida no deje modificaciones parciales."
    },
    {
      "titulo": "4C · Tablero optimizado",
      "desde": 916,
      "hasta": 1001,
      "explicacion": "Se reescriben consultas del tablero y se proponen índices de acuerdo con sus predicados y proyecciones.",
      "comprobacion": "Comparar los planes de ejecución del script y comprobar que las consultas devuelvan los mismos resultados de negocio."
    }
  ],
  "inventario": [
    {
      "titulo": "1.1 · SP_REGISTRAR_PRODUCTO",
      "desde": 62,
      "hasta": 165,
      "explicacion": "Valida precio superior al costo y existencia de categoría antes de insertar. Usa SEQ_PRODUCTO para el identificador y captura DUP_VAL_ON_INDEX.",
      "comprobacion": "Probar código repetido, categoría inexistente y precio inválido; revisar que la secuencia no colisione con los IDs precargados."
    },
    {
      "titulo": "1.2 · SP_AJUSTAR_STOCK",
      "desde": 166,
      "hasta": 330,
      "explicacion": "Distingue ENTRADA, SALIDA y AJUSTE; bloquea la existencia para calcular el saldo y registra el movimiento en la misma transacción.",
      "comprobacion": "Verificar saldo no negativo y correspondencia con el movimiento. La creación concurrente de una existencia nueva requiere tratar duplicados."
    },
    {
      "titulo": "1.3 · SP_CREAR_PEDIDO",
      "desde": 331,
      "hasta": 407,
      "explicacion": "Consulta estado del cliente y crédito disponible, rechaza clientes inactivos o sin cupo y crea cabecera BORRADOR.",
      "comprobacion": "Probar ambos rechazos por separado y comprobar el ID devuelto en un caso válido."
    },
    {
      "titulo": "2.1 · FN_STOCK_DISPONIBLE",
      "desde": 411,
      "hasta": 454,
      "explicacion": "El parámetro opcional de bodega define si se suma el stock local o consolidado. NVL(SUM(...),0) resuelve la ausencia de registros sin excepción.",
      "comprobacion": "Comparar la suma consolidada con las bodegas individuales y consultar un producto inexistente."
    },
    {
      "titulo": "2.2 · FN_CUPO_DISPONIBLE",
      "desde": 455,
      "hasta": 501,
      "explicacion": "Resta el saldo pendiente del cupo y devuelve cero si el cliente está inactivo, no existe o el resultado es negativo.",
      "comprobacion": "Un cliente activo con cupo 1.000.000 y saldo 700.000 tendría 300.000 disponibles."
    },
    {
      "titulo": "2.3 · FN_CALCULAR_DESCUENTO",
      "desde": 502,
      "hasta": 565,
      "explicacion": "Calcula 8 % desde 2.000.000 o 5 % desde 800.000; añade 2 % si no hay saldo pendiente y limita el porcentaje a 10 %. Devuelve pesos, no porcentaje.",
      "comprobacion": "Para 2.000.000 y saldo pendiente cero, el descuento esperado es 200.000."
    },
    {
      "titulo": "2.4 · Función definida por el usuario en SELECT",
      "desde": 566,
      "hasta": 593,
      "explicacion": "Invoca FN_CUPO_DISPONIBLE por cliente activo y ordena por el valor calculado. Una función invocada desde SQL debe respetar las restricciones de efectos secundarios del contexto.",
      "comprobacion": "Comprobar clientes activos y orden descendente."
    },
    {
      "titulo": "3.1 · Cursor explícito",
      "desde": 597,
      "hasta": 647,
      "explicacion": "OPEN inicia el resultado, FETCH recupera cada fila, %NOTFOUND termina el bucle y CLOSE libera el cursor. La vista consolidada aporta el stock por producto.",
      "comprobacion": "El reporte debe mostrar únicamente stock inferior al mínimo y las unidades faltantes."
    },
    {
      "titulo": "3.2 · Cursor parametrizado",
      "desde": 648,
      "hasta": 698,
      "explicacion": "Los parámetros propios del cursor permiten reutilizar la consulta para otro cliente o intervalo. LEFT JOIN con detalle conserva pedidos sin líneas.",
      "comprobacion": "Caso solicitado: cliente 501 durante 2026, pedidos CONFIRMADOS."
    },
    {
      "titulo": "3.3 · Cursor FOR UPDATE",
      "desde": 699,
      "hasta": 782,
      "explicacion": "Bloquea las filas seleccionadas y WHERE CURRENT OF modifica la fila actual del cursor. El cierre del cursor no libera los bloqueos transaccionales.",
      "comprobacion": "Comprobar que productos inactivos queden intactos y que los precios respeten el margen mínimo."
    },
    {
      "titulo": "3.4 · SYS_REFCURSOR",
      "desde": 783,
      "hasta": 839,
      "explicacion": "El procedimiento devuelve un cursor abierto mediante un parámetro OUT; el bloque consumidor recupera las filas y lo cierra.",
      "comprobacion": "Verificar que los movimientos correspondan al producto y estén ordenados por fecha."
    },
    {
      "titulo": "3.5 · BULK COLLECT y FORALL",
      "desde": 840,
      "hasta": 893,
      "explicacion": "Agrupa transferencias de filas entre SQL y PL/SQL para reducir cambios de contexto. LIMIT controla el consumo de memoria al recuperar lotes.",
      "comprobacion": "Comparar con una actualización fila a fila en un volumen suficiente; no hay tiempo medido aquí."
    },
    {
      "titulo": "4.1 · FN_PRECIO_PRODUCTO",
      "desde": 897,
      "hasta": 962,
      "explicacion": "SELECT INTO exige exactamente una fila. NO_DATA_FOUND devuelve −1 y TOO_MANY_ROWS −2 según el contrato del ejercicio; una restricción UNIQUE sobre código impide normalmente el segundo caso.",
      "comprobacion": "Probar código válido e inexistente; no eliminar restricciones en producción para forzar el caso múltiple."
    },
    {
      "titulo": "4.2 · Excepción de stock insuficiente",
      "desde": 963,
      "hasta": 1028,
      "explicacion": "La excepción e_stock_bajo nombra una condición de negocio, se levanta con RAISE y se captura en el manejador.",
      "comprobacion": "Solicitar más unidades de las disponibles y contrastar con un despacho válido."
    },
    {
      "titulo": "4.3 · Anulación de pedido",
      "desde": 1029,
      "hasta": 1128,
      "explicacion": "RAISE_APPLICATION_ERROR distingue pedido inexistente (−20010), ya anulado (−20011) y antigüedad superior a 30 días (−20012).",
      "comprobacion": "Ejecutar las tres condiciones y un pedido válido; revisar el código devuelto por Oracle."
    },
    {
      "titulo": "4.4 · PRAGMA EXCEPTION_INIT",
      "desde": 1129,
      "hasta": 1167,
      "explicacion": "Asocia ORA-02291 a una excepción de nombre propio para manejar específicamente una referencia padre inexistente.",
      "comprobacion": "Intentar insertar un producto con categoría ausente en un esquema de prueba."
    },
    {
      "titulo": "4.5 · Registro autónomo de errores",
      "desde": 1168,
      "hasta": 1234,
      "explicacion": "PRAGMA AUTONOMOUS_TRANSACTION permite confirmar el registro de error independientemente de la transacción principal. El diagnóstico SQLCODE/SQLERRM debe preservarse desde el contexto que capturó la excepción.",
      "comprobacion": "Provocar un error y revertir la transacción principal; comprobar el registro y su contenido."
    },
    {
      "titulo": "5.1 · BEFORE INSERT de cliente",
      "desde": 1241,
      "hasta": 1299,
      "explicacion": "Antes de guardar se completan identificador y estado si faltan y se normaliza el nombre con :NEW.",
      "comprobacion": "Insertar nombre con espacios y minúsculas; comprobar valores almacenados."
    },
    {
      "titulo": "5.2 · AFTER UPDATE de precio",
      "desde": 1300,
      "hasta": 1356,
      "explicacion": "La cláusula WHEN condiciona el disparo al cambio real de precio. Se registra el valor anterior, nuevo y variación porcentual; se evita dividir por cero.",
      "comprobacion": "Actualizar un precio a un valor distinto y después al mismo valor; solo el cambio real debe generar auditoría."
    },
    {
      "titulo": "5.3 · Validación de margen mínimo",
      "desde": 1357,
      "hasta": 1426,
      "explicacion": "BEFORE INSERT OR UPDATE permite impedir un precio que incumpla costo × (1 + margen/100). Una categoría inválida debe rechazarse mediante la validación o restricción correspondiente.",
      "comprobacion": "Probar precio por debajo del umbral y otro exactamente igual; verificar −20020 en el primer caso."
    },
    {
      "titulo": "5.4 · Descuento de inventario",
      "desde": 1427,
      "hasta": 1483,
      "explicacion": "AFTER INSERT del detalle registra la salida y descuenta la existencia. AFTER significa después de la operación de fila, no después de COMMIT: un error puede revertir toda la sentencia.",
      "comprobacion": "Probar cantidad superior al stock y comprobar −20030 y ausencia de cambios parciales."
    },
    {
      "titulo": "5.5 · Tabla mutante y trigger compuesto",
      "desde": 1484,
      "hasta": 1551,
      "explicacion": "Consultar DETALLE_PEDIDO desde su trigger de fila puede provocar ORA-04091. El trigger compuesto acumula identificadores afectados y recalcula cuando termina la sentencia.",
      "comprobacion": "Insertar, actualizar y eliminar líneas, incluidas sentencias de varias filas; comprobar total de la cabecera."
    },
    {
      "titulo": "5.6 · INSTEAD OF sobre vista",
      "desde": 1552,
      "hasta": 1589,
      "explicacion": "La vista consolidada contiene agregaciones; el trigger redirige los cambios de precio y stock mínimo hacia PRODUCTO. El stock total no identifica una bodega de destino.",
      "comprobacion": "Actualizar campos permitidos y comprobar que se rechace la modificación del stock calculado."
    },
    {
      "titulo": "6 · Paquete PKG_VENTAS y facturación",
      "desde": 1590,
      "hasta": 1749,
      "explicacion": "El paquete integra validación de BORRADOR, recorrido de líneas, descuento, cupo, actualización del pedido y saldo del cliente. Reutiliza funciones previas y concentra el flujo de negocio.",
      "comprobacion": "Probar pedido válido y crédito insuficiente; revisar atomicidad, bloqueos y ausencia de descuentos duplicados de inventario."
    }
  ],
  "taller-mql": [
    {
      "titulo": "1 · Insertar un alojamiento",
      "desde": 7,
      "hasta": 7,
      "explicacion": "insertOne recibe un documento BSON; se fija un ID reproducible y Decimal128 para el precio.",
      "comprobacion": "Un documento insertado con precio 150."
    },
    {
      "titulo": "2 · Documento anidado de dirección",
      "desde": 9,
      "hasta": 9,
      "explicacion": "La dirección se representa como subdocumento; address.market y address.country permiten consultas por ruta.",
      "comprobacion": "Verificar país Chile y mercado Santiago."
    },
    {
      "titulo": "3 · Insertar dos alojamientos",
      "desde": 11,
      "hasta": 11,
      "explicacion": "insertMany agrupa varias inserciones en una operación; cada documento conserva su propio ID.",
      "comprobacion": "Dos documentos con precios 80 y 110."
    },
    {
      "titulo": "4 · Insertar un array de servicios",
      "desde": 13,
      "hasta": 13,
      "explicacion": "amenities almacena varios valores en una sola propiedad.",
      "comprobacion": "El array contiene Wifi, Kitchen y Free parking."
    },
    {
      "titulo": "5 · Duplicar _id",
      "desde": 15,
      "hasta": 15,
      "explicacion": "El índice único de _id impide insertar el mismo identificador dos veces.",
      "comprobacion": "Error E11000 esperado."
    },
    {
      "titulo": "6 · Alojamientos en Brasil",
      "desde": 17,
      "hasta": 17,
      "explicacion": "La notación de punto filtra el país; la proyección limita campos y omite _id.",
      "comprobacion": "Solo documentos de Brasil; nombres y precios visibles."
    },
    {
      "titulo": "7 · Más de cinco camas",
      "desde": 18,
      "hasta": 18,
      "explicacion": "$gt establece un límite estrictamente superior; la proyección conserva nombre y cantidad de reseñas.",
      "comprobacion": "Ningún resultado tiene beds ≤ 5."
    },
    {
      "titulo": "8 · Precio inferior a 75",
      "desde": 19,
      "hasta": 19,
      "explicacion": "$lt excluye el límite 75; el precio se compara como valor numérico.",
      "comprobacion": "Todos los precios son menores a 75."
    },
    {
      "titulo": "9 · Apartamentos en Nueva York",
      "desde": 20,
      "hasta": 20,
      "explicacion": "$and exige que ambas condiciones sean verdaderas.",
      "comprobacion": "Cada resultado satisface ambos filtros."
    },
    {
      "titulo": "10 · Tipos House o Condominium",
      "desde": 21,
      "hasta": 21,
      "explicacion": "$in acepta cualquiera de los valores especificados sin repetir condiciones.",
      "comprobacion": "Cada resultado pertenece a uno de los dos tipos."
    },
    {
      "titulo": "11 · Búsqueda Luxury",
      "desde": 22,
      "hasta": 22,
      "explicacion": "$regex busca texto y la opción i ignora mayúsculas y minúsculas.",
      "comprobacion": "Los nombres coinciden con Luxury sin distinguir mayúsculas."
    },
    {
      "titulo": "12 · Servicio Heating",
      "desde": 23,
      "hasta": 23,
      "explicacion": "La igualdad sobre un array encuentra documentos que contienen el elemento.",
      "comprobacion": "Cada array contiene Heating."
    },
    {
      "titulo": "13 · Exactamente veinte servicios",
      "desde": 24,
      "hasta": 24,
      "explicacion": "$size comprueba el número exacto de elementos.",
      "comprobacion": "Cada array tiene longitud 20."
    },
    {
      "titulo": "14 · Diez precios más altos",
      "desde": 25,
      "hasta": 25,
      "explicacion": "sort descendente y limit seleccionan los diez primeros; _id desempata.",
      "comprobacion": "Máximo diez filas en orden descendente."
    },
    {
      "titulo": "15 · Sin fecha de última reseña",
      "desde": 26,
      "hasta": 26,
      "explicacion": "La igualdad con null encuentra tanto campos nulos como ausentes; se ordena por reseñas.",
      "comprobacion": "Cada documento carece de last_review o lo tiene nulo."
    },
    {
      "titulo": "16 · Modificar tipo del alojamiento",
      "desde": 28,
      "hasta": 28,
      "explicacion": "$set reemplaza solo property_type y conserva los otros campos.",
      "comprobacion": "Consultar el documento por ID y revisar property_type."
    },
    {
      "titulo": "17 · Actualizar dirección y añadir Smart TV",
      "desde": 29,
      "hasta": 29,
      "explicacion": "$set modifica la ruta anidada y $push agrega un elemento al array.",
      "comprobacion": "El documento contiene Smart TV en amenities."
    },
    {
      "titulo": "18 · Incrementar reseñas en España",
      "desde": 30,
      "hasta": 30,
      "explicacion": "updateMany aplica $inc a todos los documentos españoles con conteo numérico; repetir incrementa otra vez.",
      "comprobacion": "Comparar matchedCount y modifiedCount; el valor sube en uno."
    },
    {
      "titulo": "19 · Eliminar Cable TV",
      "desde": 31,
      "hasta": 31,
      "explicacion": "$pull quita del array todos los elementos iguales a Cable TV.",
      "comprobacion": "Ningún documento modificado conserva Cable TV."
    },
    {
      "titulo": "20 · Upsert de mansión",
      "desde": 32,
      "hasta": 32,
      "explicacion": "upsert actualiza una coincidencia o inserta un nuevo documento si no existe; $setOnInsert solo actúa al insertar.",
      "comprobacion": "Revisar matchedCount o upsertedId y consultar el documento."
    },
    {
      "titulo": "21 · Contar alojamientos con más de diez servicios",
      "desde": 35,
      "hasta": 35,
      "explicacion": "El índice 10 del array existe cuando hay al menos once elementos; $count resume la cantidad.",
      "comprobacion": "Un conteo; si no hay coincidencias $count no genera documento."
    },
    {
      "titulo": "22 · Precio promedio por país",
      "desde": 36,
      "hasta": 36,
      "explicacion": "$group agrupa por país y $avg calcula la media de valores numéricos.",
      "comprobacion": "Una fila por país con media numérica."
    },
    {
      "titulo": "23 · Cinco servicios frecuentes",
      "desde": 37,
      "hasta": 37,
      "explicacion": "$unwind genera una fila por servicio, $group cuenta y $sort más $limit seleccionan los cinco primeros.",
      "comprobacion": "Hasta cinco filas ordenadas por frecuencia."
    },
    {
      "titulo": "24 · Conteo por tipo",
      "desde": 38,
      "hasta": 38,
      "explicacion": "$match excluye tipos inválidos, $group cuenta y $sort ordena por frecuencia.",
      "comprobacion": "Una fila por tipo."
    },
    {
      "titulo": "25 · Conversión de precio",
      "desde": 39,
      "hasta": 39,
      "explicacion": "$convert transforma a entero y permite manejar valores nulos o inválidos; se conserva el precio original.",
      "comprobacion": "El campo price_entero representa la conversión; revisar nulos."
    },
    {
      "titulo": "26 · Promedio de calificación",
      "desde": 40,
      "hasta": 40,
      "explicacion": "$match exige diez reseñas o más y $avg ignora calificaciones ausentes.",
      "comprobacion": "Una media global de calificaciones disponibles."
    },
    {
      "titulo": "27 · Rangos de precio",
      "desde": 42,
      "hasta": 42,
      "explicacion": "$bucket usa límites inferiores inclusivos y superiores exclusivos. Se explicita la convención de rangos para precios decimales.",
      "comprobacion": "Revisar límites 101, 301 y 1000 y el grupo superior."
    },
    {
      "titulo": "28 · Reunión con anfitriones",
      "desde": 44,
      "hasta": 44,
      "explicacion": "$lookup relaciona host.host_id con host_id de una colección hosts hipotética; solo se ejecuta si existe dicha colección.",
      "comprobacion": "El resultado contiene un array anfitrion, posiblemente vacío."
    },
    {
      "titulo": "29 · Capacidad promedio por tipo",
      "desde": 45,
      "hasta": 45,
      "explicacion": "$avg calcula el número promedio de huéspedes por tipo de alojamiento.",
      "comprobacion": "Una media por tipo ordenada de mayor a menor."
    },
    {
      "titulo": "30 · Reseñas agrupadas por año",
      "desde": 46,
      "hasta": 46,
      "explicacion": "$year extrae el año de la fecha last_review y $group contabiliza alojamientos con esa fecha.",
      "comprobacion": "Una fila por año; no equivale a contar todas las reseñas individuales."
    }
  ]
};
