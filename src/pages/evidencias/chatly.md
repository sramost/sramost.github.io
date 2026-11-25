---
layout: ../../layouts/ChatlyLayout.astro
title: "Chatly — Proyecto final"
---
## 1. Problema, solución y alcance

Chatly es un sistema web de mensajería inspirado en WhatsApp. El problema de ingeniería consiste en almacenar dos clases de información con necesidades diferentes: datos estructurados y relacionados, que exigen integridad, y mensajes de contenido variable que crecen continuamente. Se eligió una arquitectura híbrida para aprovechar las capacidades de cada motor sin duplicar perfiles o grupos en los documentos.

El alcance incluye registro, autenticación, contactos, chats privados y grupales, estados multimedia, historial, notificaciones y bloqueos. No incluye llamadas, videollamadas ni cifrado de extremo a extremo. El objetivo académico es integrar modelado, lógica de negocio, transacciones, NoSQL, virtualización y gestión de TI.

## 2. Arquitectura y decisiones técnicas

| Capa | Tecnología | Responsabilidad |
|---|---|---|
| Presentación | Angular | Componentes, formularios, navegación y consultas periódicas |
| Aplicación | Spring Boot | API REST, validación, seguridad y coordinación |
| Persistencia relacional | PostgreSQL | Ocho tablas, procedimientos, funciones y triggers |
| Persistencia documental | MongoDB | Colección Mensaje |
| Archivos | Sistema de archivos del servidor | Imágenes, videos y documentos; se guardan referencias URL en las bases |

Angular no se conecta directamente a los motores. La API recibe DTO, ejecuta servicios y accede a repositorios JPA o MongoRepository. PostgreSQL aporta llaves foráneas y transacciones; MongoDB permite guardar cada mensaje como documento independiente. La flexibilidad documental no demuestra por sí sola mayor rendimiento: se debe medir.

## 3. Supuestos de diseño

| ID | Regla |
|---|---|
| S1–S2 | Identificación por teléfono único y autenticación obligatoria |
| S3–S4 | Contactos sin duplicados ni autorreferencias; alta automática del emisor en la agenda del receptor |
| S5–S7 | Membresía única, roles y reasignación de administrador al salir |
| S8–S9 | Mensajes independientes en MongoDB; modificación y eliminación por el emisor |
| S10–S11 | Estados multimedia de 24 horas e historial privado |
| S12 | Notificaciones al agregar a grupos y publicar estados |
| S13–S15 | Navegadores de escritorio; sin llamadas ni cifrado extremo a extremo; dos VM Linux |
| S16–S18 | Bloqueos afectan estados, notificaciones, incorporación a grupos y mensajes |

## 4. Modelado relacional y diccionario

| Tabla | Clave primaria | Atributos y relaciones principales |
|---|---|---|
| usuarios | id | nombres, apellidos, teléfono único, fecha_registro, foto_perfil_url, contrasenia |
| contactos | id | id_usuario e id_usuario_contacto referencian usuarios; fecha_agregado, nombre_personalizado |
| bloqueos | id_bloqueo | id_usuario e id_usuario_bloqueado referencian usuarios; fecha |
| grupos | id | id_creador referencia usuarios; nombre, foto_perfil_url, fecha_registro |
| miembros_grupo | id_miembro | id_grupo e id_usuario; rol |
| estados | id | id_usuario, tipo, contenido_url, descripcion, fecha_publicacion, fecha_expiracion |
| historial_estados | id | id_estado histórico, id_usuario, tipo, contenido_url, descripcion, fechas de publicación, expiración y eliminación |
| notificaciones | id | id_usuario receptor, id_usuario_origen opcional, leido, tipo, fecha |

El modelo conceptual distingue el usuario que agrega del usuario agregado, y el bloqueador del bloqueado. Son relaciones dirigidas. Un usuario crea múltiples grupos; usuarios y grupos tienen relación N:M resuelta por miembros_grupo, donde se almacena el rol. Un usuario publica múltiples estados y recibe múltiples notificaciones. El historial conserva id_estado sin FK al estado original para sobrevivir a su eliminación. La correspondencia estado–historial es lógica; el DDL recibido no impone unicidad sobre id_estado, por lo que no se afirma una relación 1:1 garantizada físicamente.

**Normalización:** 1FN: atributos escalares y ausencia de listas dentro de las tablas. 2FN: cada atributo depende de la clave de su registro; el rol pertenece a la membresía, no al usuario global. 3FN: los nombres y teléfonos no se repiten en contactos o membresías; se consultan por referencia. El historial es una copia deliberada para auditoría. Las entidades JPA declaran unicidad compuesta de contactos y membresías, aunque el script de creación recibido no incluye esas dos restricciones; conviene comprobarlas en la instancia efectiva.

## 5. PostgreSQL: procedimientos, funciones y triggers

El apéndice interactivo de esta página presenta el DDL y las definiciones PL/pgSQL originales recuperadas del script varios. Las operaciones de escritura se invocan mediante @Procedure, las consultas mediante @Query nativa. Por ejemplo:

```java
@Procedure(procedureName = "SP_BLOQUEAR_USUARIO")
public void bloquearUsuario(
    @Param("P_ID_USUARIO") Long idUsuario,
    @Param("P_ID_USUARIO_BLOQUEADO") Long idUsuarioBloqueado);
```

El servicio valida que el identificador corresponda al usuario autenticado y llama al repositorio dentro de @Transactional. La base verifica existencia de usuarios, autorreferencia y duplicados. Los errores personalizados llegan al manejador global.

- Usuarios: creación, actualización y eliminación; la eliminación bloquea el usuario con FOR UPDATE y gestiona dependencias y grupos.
- Contactos: alta, baja, alias y búsqueda por usuario.
- Bloqueos: consulta dirigida y comprobación bilateral para mensajería.
- Grupos: alta, membresía, expulsión, cambio de rol y salida con reasignación.
- Estados: creación, expiración y auditoría mediante funciones de trigger.
- Notificaciones: listado, conteo y marcado individual o masivo.

El historial se consulta mediante una entidad @Immutable; su escritura pertenece a la base de datos. El script contiene redefiniciones de funciones de trigger; se conservan en el orden original, sin confundir las versiones con objetos diferentes.

### Transacciones y excepciones

@Transactional delimita operaciones relacionales; una excepción no controlada normalmente provoca rollback según las reglas del gestor transaccional. No equivale a una transacción distribuida entre PostgreSQL, MongoDB y archivos. FOR UPDATE evita que otra transacción modifique simultáneamente la fila bloqueada, pero no resuelve por sí solo todos los conflictos.

| SQLSTATE | HTTP |
|---|---|
| P1001, P1002, P1003, P1006 | 404 |
| P1004, P1007, P1008 | 409 |
| P1005 | 403 |
| Otros | 500 con mensaje genérico |

La clase GlobalExceptionHandler recupera SQLException de la cadena de causas y limpia el mensaje antes de devolverlo.

Ejemplo de prueba propuesta en una base desechable (IDs deben existir):

```sql
BEGIN;
CALL sp_bloquear_usuario(1, 2);
SELECT * FROM bloqueos WHERE id_usuario = 1;
ROLLBACK;
```

Se espera que el bloqueo desaparezca tras revertir; no se presenta como prueba ejecutada.

## 6. MongoDB: modelo documental

Cada mensaje guarda referencias numéricas a usuarios y grupos existentes en PostgreSQL. Ejemplo ilustrativo de un mensaje privado:

```javascript
{
  idEmisor: NumberLong(1),
  idReceptor: NumberLong(2),
  idGrupo: null,
  tipo: "TEXTO",
  texto: "Hola",
  contenidoUrl: null,
  nombreArchivo: null,
  fecha: ISODate("2026-11-11T15:00:00Z"),
  leido: false,
  editado: false
}
```

El identificador _id lo gestiona MongoDB. Para mensajes grupales se usa idGrupo y se deja idReceptor nulo. Para imágenes y archivos se almacena la URL, no el binario. La clase Mensaje contiene campos fijos opcionales; dimensiones y tamaño no aparecen en el código recibido, aunque la justificación conceptual menciona esos metadatos.

### CRUD y consultas

El servicio MensajeService utiliza insert para crear, findById y save para editar, consultas de repositorio para leer y eliminación condicionada por emisor. Las siguientes operaciones MQL ilustran el equivalente de las consultas del código, con IDs ficticios:

```javascript
db.Mensaje.find({
  $or: [
    {idEmisor: 1, idReceptor: 2},
    {idEmisor: 2, idReceptor: 1}
  ]
}).sort({fecha: 1})

db.Mensaje.find({idGrupo: 5}).sort({fecha: 1})

db.Mensaje.updateMany(
  {idReceptor: 2, idEmisor: 1, leido: false},
  {$set: {leido: true}}
)

db.Mensaje.aggregate([
  {$match: {idReceptor: 2, leido: false}},
  {$group: {_id: "$idEmisor", total: {$sum: 1}}}
])
```

El OR reúne ambos sentidos de una conversación. La agregación cuenta documentos pendientes por emisor; no cuenta lecturas individuales de cada miembro de un grupo. El borrado filtra por _id e idEmisor, y la edición comprueba el emisor y el tipo TEXTO.

### Índices propuestos

```javascript
db.Mensaje.createIndex({idEmisor:1,idReceptor:1,fecha:1})
db.Mensaje.createIndex({idGrupo:1,fecha:1})
db.Mensaje.createIndex({idReceptor:1,leido:1,idEmisor:1})
```

Son propuestas coherentes con los patrones de acceso. Su creación efectiva y rendimiento deben comprobarse con explain("executionStats"). No se inventan tiempos ni resultados.

## 7. Integración con Spring Boot

El envío valida existencia del emisor, tipo TEXTO/IMAGEN/ARCHIVO, texto no vacío de hasta 2000 caracteres, destino exclusivo (receptor o grupo), ausencia de bloqueo para privados y membresía para grupos. Después inserta en MongoDB. En mensajes privados intenta agregar el emisor a la agenda del receptor en PostgreSQL; si falla, captura la excepción y conserva el mensaje.

```java
if ((dto.getIdReceptor() == null) == (dto.getIdGrupo() == null)) {
    return 5;
}
// Tras validar existencia, bloqueo o membresía:
mensajeRepo.insert(m);
if (dto.getIdGrupo() == null) {
    try {
        contactoService.agregarSiNoExiste(dto.getIdReceptor(), dto.getIdEmisor());
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

El riesgo R04 es precisamente la inconsistencia entre motores. Una mejora sería implementar operaciones idempotentes y reconciliación de referencias huérfanas. Los servicios de eliminación de usuarios y grupos recibidos llaman procedimientos PostgreSQL sin mostrar limpieza MongoDB; no se puede afirmar que RNF07 esté satisfecho.

### API y seguridad

| Ruta base | Operaciones |
|---|---|
| /auth | Registro e inicio de sesión |
| /usuarios | Perfil, actualización y eliminación |
| /contactos | Alta, baja, búsqueda y alias |
| /bloqueos | Bloquear, desbloquear y listar |
| /grupos | Gestión de grupos, roles y miembros |
| /mensajes | Envío, conversación, lectura, edición y eliminación |
| /estados | Publicación y consulta |
| /historial-estados | Consulta histórica |
| /notificaciones | Listado, conteo y lectura |

Spring Security usa BCrypt para contraseñas, JWT HS256 con vigencia de una hora y sesión stateless. Swagger declara BearerAuth. El filtro verifica la firma y la expiración. La identidad se comprueba explícitamente en bloqueo y eliminación de cuenta; no está demostrado en todas las rutas. Los archivos se sirven mediante /uploads/**; la privacidad de adjuntos requiere revisión. La utilidad AES presente no demuestra cifrado de mensajes y no se publican claves.

## 8. Frontend Angular

La pantalla principal mantiene contactos, grupos, chat activo y mensajes mediante signals. Los componentes hijos reciben datos por @Input y emiten acciones por @Output. RxJS subscribe procesa respuestas; forkJoin permite agregar varios miembros y conservar la información de errores parciales.

```typescript
this.intervalo = setInterval(() => this.cargar(), 3000);
this.intervaloContactos = setInterval(
  () => this.listarContactos(this.idUsuario), 10000
);
```

El polling consulta mensajes y no leídos cada tres segundos y contactos cada diez segundos. ChatContacto revisa bloqueos cada tres segundos y deshabilita el envío. ChatGrupo muestra opciones administrativas según rol; esta condición visual no sustituye autorización en backend. La estética usa fondo oscuro, bordes gruesos y acentos amarillo, rosa y azul. Los archivos recibidos permiten analizar estas pantallas, pero no ejecutar ni compilar el frontend completo.

## 9. Reportes SQL

### Usuarios con más contactos

```sql
SELECT u.id, u.primer_nombre || ' ' || u.primer_apellido AS usuario,
       COUNT(c.id) AS total_contactos
FROM usuarios u LEFT JOIN contactos c ON c.id_usuario = u.id
GROUP BY u.id, u.primer_nombre, u.primer_apellido
ORDER BY total_contactos DESC;
```

LEFT JOIN conserva usuarios sin contactos y COUNT(c.id) devuelve cero. El reporte original documenta un máximo de cinco contactos.

### Grupos con más miembros

```sql
SELECT g.id, g.nombre, COUNT(m.id_miembro) AS total_miembros
FROM grupos g LEFT JOIN miembros_grupo m ON m.id_grupo = g.id
GROUP BY g.id, g.nombre
ORDER BY total_miembros DESC;
```

Reconstrucción de la consulta a partir del objetivo del reporte. El documento registra un grupo con cinco miembros.

### Estados publicados

```sql
SELECT u.id, u.primer_nombre || ' ' || u.primer_apellido AS usuario,
       COUNT(e.id) AS total_estados
FROM usuarios u LEFT JOIN estados e ON e.id_usuario = u.id
GROUP BY u.id, u.primer_nombre, u.primer_apellido
ORDER BY total_estados DESC;
```

El documento registra tres usuarios con al menos un estado. Esta consulta cuenta filas en estados, no todo el historial.

### Notificaciones sin leer

```sql
SELECT r.primer_nombre AS receptor, o.primer_nombre AS origen,
       n.tipo, n.fecha
FROM notificaciones n
JOIN usuarios r ON r.id = n.id_usuario
JOIN usuarios o ON o.id = n.id_usuario_origen
WHERE n.leido = FALSE
ORDER BY n.fecha DESC;
```

Dos alias identifican al receptor y origen. Un LEFT JOIN sobre origen sería necesario si se quisieran conservar notificaciones de origen nulo. Resultados descritos en el documento del equipo, no reejecutados aquí.

## 10. Virtualización e infraestructura

Se eligió Ubuntu Server 26.04 LTS según el documento del equipo, comparado con Debian y Rocky Linux por soporte, paquetes, documentación, familiaridad y configuración. VirtualBox aloja dos VM con red host-only e IP fija. Un adaptador adicional permitió instalar paquetes. PostgreSQL se instaló mediante apt, se configuró escucha y acceso SCRAM en pg_hba.conf, se creó el rol y base y se cargó el esquema. MongoDB se instaló mediante su repositorio oficial y se crearon usuarios administrativos y de aplicación. La colección se crea al llegar el primer mensaje.

El código de configuración recibido corresponde al entorno cloud (Neon y Atlas); la documentación describe el entorno virtualizado. No se comprueba aquí que las VM estén actualmente activas. Configuración ilustrativa sin credenciales:

```properties
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
spring.mongodb.uri=${MONGODB_URI}
spring.jwt.secret=${JWT_SECRET}
spring.jwt.expirationtime=3600000
```

## 11. Gestión del proyecto

Periodo: 22 de septiembre a 11 de noviembre de 2026. Tres integrantes, siete semanas completas más dos días. Capacidad estimada: 210 a 315 horas; referencia de 262,5 horas, no registro de horas efectivas.

| Actividad | Semanas |
|---|---|
| Propuesta y supuestos | S1 |
| Gestión y modelado | S1–S2 |
| Reportes | S3 |
| Selección SO y motor | S2–S3 |
| PostgreSQL | S2–S5 |
| VM PostgreSQL | S3–S4 |
| Backend y frontend | S3–S6 |
| Bloqueos, estados y notificaciones | S4–S6 |
| Modelo y VM MongoDB | S5–S6 |
| Mensajes e integración VM | S6–S7 |
| Pruebas | S7 |
| Documentación y cierre | S7–S8 |

| Hito | Fecha |
|---|---|
| H1 Diseño | 12 octubre |
| H2 Base de datos | 26 octubre |
| H3 Aplicación integrada | 31 octubre |
| H4 Mensajes y pruebas | 8 noviembre |
| H5 Entrega final | 11 noviembre |

Organización: equipo de tres personas con responsabilidades de diseño de datos, backend, frontend, integración y documentación. Mi participación se centró en backend, frontend, bloqueos, integración y gestión documental según el apartado 6.2. La matriz RACI define responsable, aprobador, consultado e informado. El equipo utilizó Kanban con columnas Por hacer, En proceso, Hecho y Aprobado; límite de dos tareas en proceso por integrante y revisión en cada hito.

### Trazabilidad de requerimientos

46 RF y 23 RNF definidos en el documento 6.3. La siguiente agrupación relaciona requisitos con las clases recibidas, sin certificar aprobación funcional:

| RF | Módulo y evidencia |
|---|---|
| 01–05 | AuthController, UsuarioService, UsuarioRepository |
| 06–11 | ContactoService, ContactoRepository, MensajeService |
| 12–20 | GrupoService, GrupoRepository, Miembrogrupo |
| 21–27 | MensajeController, MensajeService, MensajeRepository |
| 28–33 | EstadoService, HistorialEstado, funciones trigger |
| 34–39 | Procedimientos de estados y grupos, NotificacionRepository |
| 40–46 | BloqueoService, fn_hay_bloqueo, validaciones de mensajes y grupos |

Los RNF establecen seguridad, privacidad, integridad, rendimiento, capacidad de 50 usuarios, fiabilidad, vigencia, usabilidad, compatibilidad y disponibilidad. Objetivos como tiempos inferiores a 2–3 segundos y 99 % de disponibilidad requieren pruebas, no se dan por cumplidos.

### Matriz de riesgos

| Probabilidad / impacto | Bajo | Medio | Alto |
|---|---|---|---|
| Alta | — | R03 | R01 |
| Media | — | R05, R06 | R02, R04 |
| Baja | — | R08 | R07, R09 |

| Riesgo | Mitigación documentada |
|---|---|
| R01 Carga académica | Priorizar Must y redistribuir tareas |
| R02 Subestimación | Controlar alcance y revisar hitos |
| R03 Aprendizaje | Prototipos y documentación |
| R04 Inconsistencia entre motores | Ordenar operaciones, manejar fallos y reconciliar |
| R05 Integración | Definir contratos e integrar incrementalmente |
| R06 Git | Ramas, fusiones frecuentes y restauración |
| R07 VM | Copias y scripts de recuperación |
| R08 Rendimiento | Pruebas con 50 usuarios e índices |
| R09 Seguridad | Validaciones, hash y pruebas de acceso |

El historial Git del aplicativo y la distribución efectiva de commits no fueron aportados; no se confunden con los commits de este portafolio.

## 12. ETL complementario

El proceso Chatly_Contactos en Pentaho Spoon extrae usuarios y contactos mediante consulta SQL, ordena por usuario, agrupa para contar, selecciona columnas y exporta CSV. Se prefiere ETL porque el reporte necesita datos transformados antes de escribir el archivo, no una carga íntegra seguida de transformación en un almacén. El registro de ejecución previamente compartido indica 24 filas extraídas y 16 registros finales, sin errores en los pasos mostrados. No se dispone aquí del archivo de transformación ni de captura nueva.

## 13. Evaluación, resultados y conclusiones

| Criterio de la rúbrica | Peso | Evidencia disponible |
|---|---:|---|
| Modelado y diseño | 20% | Diagramas, tablas, análisis de normalización |
| Relacional | 20% | DDL, procedimientos, funciones, triggers y Java |
| MongoDB | 15% | Modelo, CRUD, consultas y agregación |
| Web e integración | 15% | Controladores, servicios, repositorios y componentes |
| Gestión | 15% | Planificación, riesgos, Kanban, trazabilidad; historial Git del aplicativo pendiente |
| Documentación | 10% | Informe ejecutivo y documentos técnicos; referencias académicas por completar |
| Video y sustentación | 5% | Video no aportado |

La arquitectura permite separar reglas relacionales y documentos de mensajería. Las principales lecciones son la necesidad de contratos de integración, restricciones físicas, transacciones acotadas y comprobación de permisos por recurso. Se observó una discrepancia entre el límite multipart de 5 MB y la validación de videos de 30 MB. Las credenciales no deben formar parte del código público. Las pruebas de carga, privacidad, limpieza entre motores y recuperación son mejoras pendientes de verificación. No se presentan capturas inventadas ni se afirma haber ejecutado el sistema en esta revisión.

## Fuentes del proyecto

Documentos del equipo Chatly (noviembre de 2026): propuesta y supuestos, modelos de datos, diccionario, reportes SQL, virtualización, justificación NoSQL, planificación, organización, requerimientos, riesgos, metodología e informe ejecutivo. Scripts de creación y varios; clases Java y componentes Angular aportados. Enunciado del proyecto final de Bases de Datos 2, Universidad El Bosque. Esta página sintetiza y analiza dichas fuentes; no sustituye el video ni las pruebas de ejecución.
