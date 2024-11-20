#!/bin/bash

###
# Инициализируем бд
###

docker compose exec -T configSrv mongosh --port 27017 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
exit();
EOF

docker compose exec -T shard1-1  mongosh --port 27018 <<EOF
rs.initiate(
    {
      _id : "rs1",
      members: [
        { _id : 0, host : "shard1-1:27018" },
        { _id : 1, host : "shard1-2:27019" },
        { _id : 2, host : "shard1-3:27020" }
      ]
    }
);
exit();
EOF


docker compose exec -T shard2-1 mongosh --port 27021 <<EOF
rs.initiate(
    {
      _id : "rs2",
      members: [
        { _id : 0, host : "shard2-1:27021" },
        { _id : 1, host : "shard2-2:27022" },
        { _id : 2, host : "shard2-3:27023" }
      ]
    }
);
exit();
EOF

echo "sleep 5 - Если не подождать, следующая команда падает с ошибкой Connection Refused (по крайней мере у меня локально)"
sleep 5;

docker compose exec -T mongos_router  mongosh --port 27024 <<EOF
sh.addShard( "rs1/shard1-1:27018");
sh.addShard( "rs2/shard2-1:27021");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
exit();
EOF

