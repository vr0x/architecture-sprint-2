#!/bin/bash

# Инициализация
## Запуск докера
docker compose up -d 

# Инициализация конфигурационного сервера
docker exec configSrv mongosh --port 27017 --eval '
rs.initiate(
  {
    _id : "config_server",
    configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);'

# Инициализация первой шарды
docker exec shard1 mongosh --port 27018 --eval '
rs.initiate(
  {
    _id : "shard1",
    members: [
      { _id : 0, host : "shard1:27018" }
    ]
  }
);'

# Инициализация второй шарды
docker exec shard2 mongosh --port 27019 --eval '
rs.initiate(
  {
    _id : "shard2",
    members: [
      { _id : 1, host : "shard2:27019" }
    ]
  }
);'

# Настройка шардирования через mongos
docker exec mongos_router mongosh --port 27020 --eval '
sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });'

# Заполнение данных
docker exec mongos_router mongosh --port 27020 --eval '
db = db.getSiblingDB("somedb");
for (var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({ age: i, name: "ly" + i });
}
db.helloDoc.countDocuments();'



###
# Инициализируем бд
###

#docker compose exec -T mongodb1 mongosh <<EOF
#use somedb
#for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
#EOF

