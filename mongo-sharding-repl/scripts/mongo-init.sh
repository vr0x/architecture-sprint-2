#!/bin/bash

# Инициализация
## Запуск докера
docker compose up -d 

# Ждем немного, чтобы контейнеры успели запуститься
sleep 10

## Настройка сервера конфигурации mongodb
docker exec configSrv mongosh --port 27017 --eval '
rs.initiate({
    _id: "config_server",
    configsvr: true,
    members: [
      { _id: 0, host: "configSrv:27017" }
    ]
});'

# Ждем инициализацию конфиг сервера
sleep 5

## Настройка репликации 1 шарды
docker exec shard1-1 mongosh --port 27018 --eval '
rs.initiate({
    _id: "shard1",
    members: [
      { _id: 0, host: "shard1-1:27018" },
      { _id: 1, host: "shard1-2:27019" },
      { _id: 2, host: "shard1-3:27020" }
    ]
});'

# Ждем инициализацию первой шарды
sleep 5

## Настройка репликации 2 шарды
docker exec shard2-1 mongosh --port 27021 --eval '
rs.initiate({
    _id: "shard2",
    members: [
      { _id: 0, host: "shard2-1:27021" },
      { _id: 1, host: "shard2-2:27022" },
      { _id: 2, host: "shard2-3:27023" }
    ]
});'

# Ждем инициализацию второй шарды
sleep 5

## настройка шардирования
docker exec mongos_router mongosh --port 27025 --eval '
sh.addShard("shard1/shard1-1:27018");
sh.addShard("shard2/shard2-1:27021");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });
db = db.getSiblingDB("somedb");
for (var i = 0; i < 1000; i++) { db.helloDoc.insertOne({ age: i, name: "ly" + i }); }
db.helloDoc.countDocuments();'


###
# Инициализируем бд
###

#docker compose exec -T mongodb1 mongosh <<EOF
#use somedb
#for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
#EOF

