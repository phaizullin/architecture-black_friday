# MongoDB Sharding

## Архитектура

- **Config Server** (порт 27019) - хранит метаданные кластера
- **Shard 1** (порт 27018) - первый шард данных
- **Shard 2** (порт 27020) - второй шард данных  
- **Mongos Router** (порт 27017) - маршрутизатор запросов
- **API Application** (порт 8080) - веб-приложение для мониторинга

## Как запустить

### 1. Запуск кластера

```shell
docker compose up -d
```

### 2. Инициализация шардирования

```shell
./scripts/mongo-init.sh
```

Этот скрипт выполнит следующие шаги:
1. Инициализирует Config Server replica set
2. Инициализирует replica sets для каждого шарда
3. Добавит шарды в кластер через mongos
4. Включит шардирование для базы данных `somedb`
5. Создаст шардированную коллекцию `helloDoc`
6. Заполнит коллекцию документами
7. **Покажет количество документов на каждом шарде**

## Проверка работы

### Веб-интерфейс

Откройте в браузере:
- **Локально**: http://localhost:8080
- **На виртуальной машине**: http://<ip машины>:8080

API покажет:
- Общее количество документов в базе
- Количество документов в каждом шарде
- Информацию о топологии кластера

### Swagger документация

http://localhost:8080/docs

## Полезные команды для мониторинга

### Статус кластера

```shell
docker compose exec -T mongos mongosh --port 27017 --quiet --eval "sh.status()"
```

### Распределение данных по шардам

```shell
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
use somedb
db.helloDoc.getShardDistribution()
EOF
```

### Количество документов в каждом шарде

#### Shard 1:
```shell
docker compose exec -T shard1 mongosh --port 27018 --quiet --eval "use somedb" --eval "db.helloDoc.countDocuments()"
```

#### Shard 2:
```shell
docker compose exec -T shard2 mongosh --port 27020 --quiet --eval "use somedb" --eval "db.helloDoc.countDocuments()"
```

### Общее количество через mongos:
```shell
docker compose exec -T mongos mongosh --port 27017 --quiet --eval "use somedb" --eval "db.helloDoc.countDocuments()"
```