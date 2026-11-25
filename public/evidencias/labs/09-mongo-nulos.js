// mongosh. Usar una base de pruebas; colección exclusiva del laboratorio.
const c=db.getCollection("lab_bd2_nulos");
c.insertMany([{_id:1,x:null,a:[{n:1,v:5},{n:2,v:9}]},{_id:2,a:[{n:1,v:9}]},{_id:3,x:7}]);
printjson(c.find({x:null}).toArray()); // esperado IDs 1,2
printjson(c.find({x:{$type:"null"}}).toArray()); // ID 1
printjson(c.find({x:{$exists:false}}).toArray()); // ID 2
printjson(c.find({"a.n":1,"a.v":9}).toArray()); // IDs 1,2
printjson(c.find({a:{$elemMatch:{n:1,v:9}}}).toArray()); // ID 2
// elemMatch exige que ambas condiciones correspondan al mismo elemento.
c.drop();
