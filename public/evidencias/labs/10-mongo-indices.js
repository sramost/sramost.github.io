// mongosh: colección desechable, no usar sobre datos existentes.
const c=db.getCollection("lab_bd2_indices");
for(let i=0;i<10000;i+=1000) c.insertMany(Array.from({length:1000},(_,j)=>({_id:i+j,grupo:(i+j)%100,valor:i+j})));
const q={grupo:7,valor:{$gte:5000}};
const medir=()=>{const e=c.find(q).explain("executionStats");printjson({plan:e.queryPlanner.winningPlan,devueltos:e.executionStats.nReturned,documentos:e.executionStats.totalDocsExamined,claves:e.executionStats.totalKeysExamined,ms:e.executionStats.executionTimeMillis});};
medir();
c.createIndex({grupo:1,valor:1});
medir();
// Esperado: 50 coincidencias; examinar si disminuyen documentos leídos. Los ms varían.
c.drop();
