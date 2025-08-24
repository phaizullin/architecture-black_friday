# MongoDB Sharded Cluster с Репликацией

## 🏗 Архитектура

### Компоненты кластера:

1. **Config Server Replica Set** (1 узел)
   - `configsvr:27019` - хранит метаданные кластера (в режиме replica set)

2. **Shard 1 Replica Set** (3 узла)
   - `shard1_primary:27018` (Primary, приоритет 10)
   - `shard1_secondary1:27018` (Secondary, приоритет 5)
   - `shard1_secondary2:27018` (Secondary, приоритет 1)

3. **Shard 2 Replica Set** (3 узла) 
   - `shard2_primary:27020` (Primary, приоритет 10)
   - `shard2_secondary1:27020` (Secondary, приоритет 5)
   - `shard2_secondary2:27020` (Secondary, приоритет 1)

4. **MongoDB Router** (mongos)
   - `mongos:27017` - точка входа для клиентских приложений

5. **API Application**
   - `pymongo_api:8080` - веб-интерфейс для мониторинга


### 1. Запуск кластера

```bash
# Запуск всех сервисов (7 узлов MongoDB + mongos + API)
docker compose up -d

# Проверка статуса всех контейнеров
docker compose ps
```

### 2. Инициализация репликации и шардирования

```bash
# Выполнить автоматическую настройку кластера
./scripts/mongo-init.sh
```

Скрипт инициализации автоматически выполняет:

1. **Проверка готовности Config Server**
   - Проверка доступности одиночного config server

2. **Инициализация Shard 1 Replica Set** 
   - Создание replica set с приоритетами
   - Назначение primary узла

3. **Инициализация Shard 2 Replica Set**
   - Аналогично Shard 1
   - Настройка отказоустойчивости

4. **Добавление шардов в кластер**
   - Регистрация replica sets в mongos
   - Настройка маршрутизации

5. **Создание шардированной коллекции**
   - Включение шардирования для базы `somedb`
   - Создание коллекции `helloDoc` с hashed sharding

6. **Заполнение тестовыми данными**
   - Добавление 5000 документов
   - Автоматическое распределение по шардам

7. **Проверка состояния кластера**
   - Вывод статуса всех replica sets
   - Отображение распределения данных

### 3. Проверка работы

#### Веб-интерфейс
- **Основной API**: http://localhost:8080
- **Swagger документация**: http://localhost:8080/docs

#### Консольные команды
```bash
# Общий статус кластера
docker compose exec -T mongos mongosh --port 27017 --quiet --eval "sh.status()"
````

### Проверка Config Server
```bash
docker compose exec -T configsvr mongosh --port 27019 --quiet --eval "db.adminCommand('ping')"
```

### Статус Shard 1 Replica Set  
```bash
docker compose exec -T shard1_primary mongosh --port 27018 --quiet --eval "rs.status()"
```

### Статус Shard 2 Replica Set
```bash
docker compose exec -T shard2_primary mongosh --port 27020 --quiet --eval "rs.status()"
```

### Проверка Primary/Secondary узлов
```bash
# Какой узел является Primary для каждого replica set
docker compose exec -T shard1_primary mongosh --port 27018 --quiet --eval "db.hello().isWritablePrimary"  
docker compose exec -T shard2_primary mongosh --port 27020 --quiet --eval "db.hello().isWritablePrimary"
```
