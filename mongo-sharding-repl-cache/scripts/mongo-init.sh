#!/bin/bash


### Инициализация конфигурационного сервиса

docker compose exec -T configSrv0 mongosh --port 27000 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv0:27000" },
      { _id : 1, host : "configSrv1:27001" },
      { _id : 2, host : "configSrv2:27002" },
    ]
  }
);
exit();
EOF

### Инициализация шардов:

docker compose exec -T shard1_1 mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1_1:27018" },
        { _id : 1, host : "shard1_2:27028" },
        { _id : 2, host : "shard1_3:27038" }
      ]
    }
);
exit();
EOF

docker compose exec -T shard2_1 mongosh --port 27019 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 3, host : "shard2_1:27019" },
        { _id : 4, host : "shard2_2:27029" },
        { _id : 5, host : "shard2_3:27039" }
      ]
    }
);
exit();
EOF

### Добавление шардов в кластер и подготовка данных

docker compose exec -T mongos_router0 mongosh --port 27010 --quiet <<EOF
sh.addShard("shard1/shard1_1:27018,shard1_2:27028,shard1_3:27038");
sh.addShard("shard2/shard2_1:27019,shard2_2:27029,shard2_3:27039");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
exit();
EOF

