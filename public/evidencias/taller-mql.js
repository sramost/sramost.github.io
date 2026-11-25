// Taller MQL — reconstrucción de repaso. Ejecutar sobre una COPIA de sample_airbnb.
// mongosh: seleccionar la base de pruebas antes de ejecutar. No usar en producción.
const c = db.getCollection("listingsAndReviews");
const prefix = "bd2-repaso-";
const p = {_id:prefix+"1", name:"Cozy Cabin Retreat",summary:"A cozy cabin surrounded by nature.",property_type:"Cabin",price:NumberDecimal("150.00")};
// 1
c.insertOne(p);
// 2
c.insertOne({_id:prefix+"2",name:"Estudio Santiago",address:{country:"Chile",market:"Santiago"},amenities:[]});
// 3
c.insertMany([{_id:prefix+"3a",name:"Studio de Arte Urbano",price:NumberDecimal("80.00")},{_id:prefix+"3b",name:"Loft Minimalista",price:NumberDecimal("110.00")}]);
// 4
c.insertMany([{_id:prefix+"4",name:"Apartamento equipado",amenities:["Wifi","Kitchen","Free parking"]}]);
// 5: E11000 esperado por _id repetido
try { c.insertOne(p); } catch(e) { print(e.message); }
// 6–15: consultas y proyecciones
printjson(c.find({"address.country":"Brazil"},{_id:0,name:1,price:1}).toArray());
printjson(c.find({beds:{$gt:5}},{_id:0,name:1,number_of_reviews:1}).toArray());
printjson(c.find({price:{$lt:NumberDecimal("75")}},{_id:0,name:1,price:1,property_type:1}).toArray());
printjson(c.find({$and:[{property_type:"Apartment"},{"address.market":"New York"}]}).toArray());
printjson(c.find({property_type:{$in:["House","Condominium"]}}).toArray());
printjson(c.find({name:{$regex:"Luxury",$options:"i"}}).toArray());
printjson(c.find({amenities:"Heating"}).toArray());
printjson(c.find({amenities:{$size:20}}).toArray());
printjson(c.find({price:{$type:"number"}},{_id:0,name:1,price:1,"address.country":1}).sort({price:-1,_id:1}).limit(10).toArray());
printjson(c.find({last_review:null},{_id:0,name:1,summary:1,description:1}).sort({number_of_reviews:-1,_id:1}).toArray());
// 16–20: modificaciones (solo en copia)
printjson(c.updateOne({_id:prefix+"1"},{$set:{property_type:"Entire home/apt"}}));
printjson(c.updateOne({_id:prefix+"2"},{$set:{"address.market":"Santiago"},$push:{amenities:"Smart TV"}}));
printjson(c.updateMany({"address.country":"Spain",number_of_reviews:{$type:"number"}},{$inc:{number_of_reviews:1}}));
printjson(c.updateMany({amenities:"Cable TV"},{$pull:{amenities:"Cable TV"}}));
printjson(c.updateOne({name:"Mansión de Prueba"},{$set:{price:NumberDecimal("1500"),"address.country":"United States"},$setOnInsert:{_id:prefix+"20"}},{upsert:true}));
// 21–30: agregaciones
const run = pipeline => printjson(c.aggregate(pipeline).toArray());
run([{$match:{"amenities.10":{$exists:true}}},{$count:"total"}]);
run([{$match:{"address.country":{$type:"string"},price:{$type:"number"}}},{$group:{_id:"$address.country",promedio:{$avg:"$price"}}}]);
run([{$unwind:"$amenities"},{$group:{_id:"$amenities",frecuencia:{$sum:1}}},{$sort:{frecuencia:-1,_id:1}},{$limit:5}]);
run([{$match:{property_type:{$type:"string"}}},{$group:{_id:"$property_type",total:{$sum:1}}},{$sort:{total:-1,_id:1}}]);
run([{$project:{_id:0,name:1,price:1,price_entero:{$convert:{input:"$price",to:"int",onError:null,onNull:null}}}}]);
run([{$match:{number_of_reviews:{$gte:10}}},{$group:{_id:null,promedio:{$avg:"$review_scores.review_scores_rating"}}}]);
// 27: intervalos continuos [0,101), [101,301), [301,1000), [1000,+inf).
run([{$match:{price:{$type:"number",$gte:0}}},{$bucket:{groupBy:"$price",boundaries:[0,101,301,1000],default:"1000+",output:{total:{$sum:1}}}}]);
// 28: teórico, requiere colección hosts con host_id compatible
// c.aggregate([{$lookup:{from:"hosts",localField:"host.host_id",foreignField:"host_id",as:"anfitrion"}}]);
run([{$match:{property_type:{$type:"string"}}},{$group:{_id:"$property_type",promedio:{$avg:"$accommodates"}}},{$sort:{promedio:-1,_id:1}}]);
run([{$match:{last_review:{$type:"date"}}},{$group:{_id:{$year:"$last_review"},total:{$sum:1}}},{$sort:{_id:1}}]);
// Resultados no ejecutados aquí. Restaurar la copia antes de repetir.
