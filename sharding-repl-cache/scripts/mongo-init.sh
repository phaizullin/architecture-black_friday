#!/bin/bash

set -e

echo "Инициализация шардированного кластера MongoDB с репликацией шардов..."
echo "======================================================================"

echo "1. Инициализация Config Server Replica Set..."
docker compose exec -T configsvr mongosh --port 27019 --quiet <<EOF
try {
    rs.initiate({
        _id: "configrs",
        configsvr: true,
        members: [
            { _id: 0, host: "configsvr:27019" }
        ]
    })
    print("Config Server Replica Set инициализирован")
} catch(e) {
    print("Config server уже инициализирован или ошибка:", e.message)
}
EOF

echo "   Ожидание готовности Config Server..."
sleep 10

echo "2. Инициализация Shard 1 Replica Set..."
docker compose exec -T shard1_primary mongosh --port 27018 --quiet <<EOF
try {
    rs.initiate({
        _id: "shard1rs",
        members: [
            { _id: 0, host: "shard1_primary:27018", priority: 10 },
            { _id: 1, host: "shard1_secondary1:27018", priority: 5 },
            { _id: 2, host: "shard1_secondary2:27018", priority: 1 }
        ]
    })
    print("Shard 1 Replica Set инициализирован")
} catch(e) {
    print("Shard 1 уже инициализирован или ошибка:", e.message)
}
EOF

echo "3. Инициализация Shard 2 Replica Set..."
docker compose exec -T shard2_primary mongosh --port 27020 --quiet <<EOF
try {
    rs.initiate({
        _id: "shard2rs",
        members: [
            { _id: 0, host: "shard2_primary:27020", priority: 10 },
            { _id: 1, host: "shard2_secondary1:27020", priority: 5 },
            { _id: 2, host: "shard2_secondary2:27020", priority: 1 }
        ]
    })
    print("Shard 2 Replica Set инициализирован")
} catch(e) {
    print("Shard 2 уже инициализирован или ошибка:", e.message)
}
EOF

echo "   Ожидание готовности всех Replica Sets..."
sleep 20

echo "4. Добавление шардов в кластер..."
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
try {
    sh.addShard("shard1rs/shard1_primary:27018,shard1_secondary1:27018,shard1_secondary2:27018")
    print("Shard 1 Replica Set добавлен в кластер")
} catch(e) {
    print("Ошибка добавления Shard 1:", e.message)
}

try {
    sh.addShard("shard2rs/shard2_primary:27020,shard2_secondary1:27020,shard2_secondary2:27020")
    print("Shard 2 Replica Set добавлен в кластер")
} catch(e) {
    print("Ошибка добавления Shard 2:", e.message)
}
EOF

echo "5. Настройка шардирования базы данных..."
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
try {
    sh.enableSharding("somedb")
    print("Шардирование включено для базы somedb")
} catch(e) {
    print("Ошибка включения шардирования:", e.message)
}
EOF

echo "6. Создание шардированной коллекции..."
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
use somedb
try {
    // Создаем индекс перед шардированием
    db.helloDoc.createIndex({"name": 1})
    print("Индекс создан")
    
    // Шардируем коллекцию с hashed sharding
    sh.shardCollection("somedb.helloDoc", { "name": "hashed" })
    print("Коллекция helloDoc шардирована с hashed sharding")
} catch(e) {
    print("Ошибка создания коллекции:", e.message)
}
EOF

echo "7. Заполнение базы данными..."
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
use somedb
try {
    print("Добавление 5000 документов...")
    for(var i = 0; i < 5000; i++) {
        db.helloDoc.insertOne({
            age: i % 100,
            name: "user" + String(i).padStart(5, '0'),
            timestamp: new Date(),
            data: "sample_data_" + i
        })
        if (i % 1000 === 0 && i > 0) {
            print("Добавлено", i, "документов")
        }
    }
    print("Добавлено 5000 документов")
} catch(e) {
    print("Ошибка добавления данных:", e.message)
}
EOF

echo "8. Проверка состояния кластера..."

echo "   Общее количество документов:"
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
use somedb
var totalCount = db.helloDoc.countDocuments()
print("Всего документов:", totalCount)
EOF

echo "   Распределение данных по шардам:"
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
use somedb
try {
    db.helloDoc.getShardDistribution()
} catch(e) {
    print("Ошибка получения распределения:", e.message)
}
EOF

echo "   Статус replica sets:"
echo "      Shard 1 Replica Set:"
docker compose exec -T shard1_primary mongosh --port 27018 --quiet <<EOF
try {
    var status = rs.status()
    status.members.forEach(function(member) {
        print("     ", member.name, "-", member.stateStr)
    })
} catch(e) {
    print("     Ошибка:", e.message)
}
EOF

echo "      Shard 2 Replica Set:"
docker compose exec -T shard2_primary mongosh --port 27020 --quiet <<EOF
try {
    var status = rs.status()
    status.members.forEach(function(member) {
        print("     ", member.name, "-", member.stateStr)
    })
} catch(e) {
    print("     Ошибка:", e.message)
}
EOF

echo "9. Тестирование кэширования..."

echo "   Первый запрос:"
time curl -s http://localhost:8080/helloDoc/users | head -20

echo "   Второй запрос:"
time curl -s http://localhost:8080/helloDoc/users | head -20

