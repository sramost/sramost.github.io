export const laboratorios: Record<string, [string,string,string,string]> = {
  "01-nulos": [
    "La lógica SQL tiene TRUE, FALSE y UNKNOWN. Si se compara 2 con NULL, el resultado es UNKNOWN; NOT UNKNOWN sigue siendo UNKNOWN. Por eso una lista de exclusión que contiene 1 y NULL no permite concluir que 2 no pertenece.",
    "Primero ejecutar NOT IN sobre candidatos 1 y 2 y exclusiones 1 y NULL. Después mantener los mismos datos y cambiar únicamente el operador a NOT EXISTS. La comparación controla todas las demás variables.",
    "NOT IN: conjunto vacío. NOT EXISTS: una fila con id 2.",
    "La antiunión correlacionada comprueba coincidencias reales. Es preferible cuando la subconsulta puede contener nulos; alternativamente se puede excluir explícitamente NULL si esa es la regla de negocio."
  ],
  "02-ventanas": [
    "Una función analítica conserva las filas originales. Con montos 10,10,5, el empate permite distinguir el rango de la posición y el marco físico del lógico.",
    "Ejecutar una CTE con tres filas. Ordenar por monto descendente; para ROW_NUMBER y ROWS, agregar id como desempate. Comparar las cinco columnas calculadas.",
    "id | monto | rn | rank | dense_rank | RANGE | ROWS\n1  | 10    | 1  | 1    | 1          | 20    | 10\n2  | 10    | 2  | 1    | 1          | 20    | 20\n3  | 5     | 3  | 3    | 2          | 25    | 25",
    "RANGE incorpora todos los pares del mismo monto a la vez. ROWS acumula por posición. El total final coincide, pero el valor de cada fila intermedia cambia."
  ],
  "03-indices": [
    "Un índice B-tree ordinario sobre nombre guarda el valor original; el predicado UPPER(nombre) solicita el resultado de una expresión. La hipótesis es que un índice sobre esa expresión facilite el acceso selectivo.",
    "Crear 50.000 filas, un índice ordinario y estadísticas. Ejecutar EXPLAIN PLAN con el mismo filtro antes y después de crear el índice funcional. Comparar operaciones, predicados, cardinalidad y costo.",
    "Antes: posible TABLE ACCESS FULL. Después: posible INDEX RANGE SCAN sobre ix_lab_upper. No hay costos medidos en este laboratorio.",
    "El optimizador puede elegir otro plan dependiendo de las estadísticas y selectividad. El costo estimado no representa milisegundos; para medir tiempos y lecturas reales se necesitan estadísticas de ejecución."
  ],
  "04-concurrencia": [
    "El bloqueo de una escritura no evita una actualización perdida cuando el valor nuevo fue calculado con una lectura anterior al bloqueo. Se comparan escrituras absolutas con operaciones relativas al saldo vigente.",
    "Preparar saldo 1000. A y B leen 1000; A escribe 700 sin confirmar; B intenta escribir 800 y queda esperando; confirmar A y luego B. Reiniciar saldo y repetir con UPDATE saldo=saldo-300 y saldo=saldo-200.",
    "Escenario | Saldo final esperado\nEscritura absoluta | 800\nActualización relativa | 500\nSaldo correcto de negocio | 500",
    "La operación relativa se evalúa sobre el valor actual cuando puede adquirir el bloqueo. Si la decisión requiere varias lecturas o reglas de negocio, utilizar SELECT FOR UPDATE antes de calcular. Ejecutar cada sesión por separado."
  ],
  "05-savepoint": [
    "Una transacción permite deshacer modificaciones no confirmadas. SAVEPOINT identifica un punto intermedio sin confirmar los cambios previos.",
    "Insertar saldo 100 y confirmar. Actualizar a 90, crear SAVEPOINT ajuste, actualizar a cero y revertir al punto guardado. Consultar y después ejecutar ROLLBACK completo.",
    "Estado | Saldo esperado\nInicial confirmado | 100\nAntes de rollback | 0\nROLLBACK TO ajuste | 90\nROLLBACK | 100",
    "La reversión parcial conserva los cambios previos al savepoint dentro de la misma transacción. Evitar DDL entre las operaciones porque Oracle puede confirmar implícitamente la transacción."
  ],
  "06-excepciones": [
    "Los bloques PL/SQL pueden manejar una excepción localmente o propagarla al bloque superior. RAISE sin argumento dentro del manejador relanza la excepción actual.",
    "Habilitar SERVEROUTPUT, declarar e_regla, lanzar la excepción dentro de un bloque anidado y registrar un mensaje en cada manejador. Comparar con una variante que no relanza.",
    "Interno: registra y relanza\nExterno: maneja la excepción",
    "Con RAISE ambos mensajes deben aparecer; sin él, el bloque externo no recibe el error. Registrar un error no equivale a comunicarlo al llamador."
  ],
  "07-auditoria": [
    "Un trigger DML convencional participa en la transacción que lo activa. El registro de auditoría debe ser coherente con la modificación que lo originó.",
    "Crear producto de precio 100 y confirmar. Definir trigger AFTER UPDATE, cambiar precio a 120 y consultar auditoría antes de revertir. Después de ROLLBACK, consultar nuevamente ambas tablas.",
    "Antes de ROLLBACK: precio 120, auditoría (1,100,120).\nDespués de ROLLBACK: precio 100, auditoría vacía.",
    "AFTER no significa después de COMMIT. El trigger se ejecuta durante la sentencia y sus modificaciones se revierten con la transacción. El registro autónomo tiene garantías distintas y debe justificarse."
  ],
  "08-paquetes": [
    "Las variables privadas de un paquete PL/SQL mantienen estado en una sesión mientras la instancia del paquete siga válida. No son filas de una tabla ni forman parte del rollback de datos.",
    "Crear especificación y cuerpo con contador privado. Ejecutar dos llamadas consecutivas en sesión A y otras dos en una sesión B nueva. Probar ROLLBACK entre llamadas adicionales.",
    "Sesión A: 1, 2.\nSesión B nueva: 1, 2.\nTercera llamada en A tras ROLLBACK: 3.",
    "El estado no es global para todos los clientes; tampoco es almacenamiento persistente. En aplicaciones con pools de conexiones se debe evitar depender de un contador de sesión para reglas de negocio."
  ],
  "09-mongo-nulos": [
    "MongoDB diferencia un campo ausente de un valor BSON null. Además, dos predicados sobre un array pueden coincidir con elementos distintos si no se utiliza $elemMatch.",
    "Insertar tres documentos: el primero con x:null y dos elementos a; el segundo sin x y con un elemento que satisface ambas condiciones; el tercero con x:7. Comparar las cinco consultas del script.",
    "Consulta | IDs esperados\nx:null | 1,2\n$type:null | 1\n$exists:false | 2\na.n=1 y a.v=9 | 1,2\n$elemMatch | 2",
    "La igualdad con null no prueba existencia. $elemMatch exige que un mismo elemento cumpla ambas condiciones, lo que evita falsos positivos al consultar arrays de subdocumentos."
  ],
  "10-mongo-indices": [
    "Un índice compuesto con grupo antes de valor puede atender una igualdad por grupo y un rango por valor. La hipótesis es reducir los documentos examinados sin cambiar los resultados.",
    "Generar 10.000 documentos sintéticos, con grupo=i%100. Consultar grupo 7 y valor>=5000. Capturar executionStats, crear índice {grupo:1,valor:1} y repetir exactamente el mismo filtro.",
    "nReturned esperado: 50 en ambas ejecuciones.\nSin índice: posible COLLSCAN y 10.000 documentos examinados.\nCon índice: posible IXSCAN y FETCH con menos documentos examinados.",
    "Registrar nReturned, totalDocsExamined, totalKeysExamined y executionTimeMillis. El plan y los tiempos dependen del motor y del entorno; el resultado del filtro debe permanecer constante. El índice añade costo de almacenamiento y mantenimiento."
  ]
};
