# MongoDB Sharded Cluster с Репликацией и Кешированием

## Архитектура

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

5. **Redis Cache**
   - `redis:6379` - система кеширования для ускорения запросов

6. **API Application**
   - `pymongo_api:8080` - веб-интерфейс с кешированием

## 🚀 Быстрый старт

### 1. Запуск кластера

```bash
# Запуск всех сервисов (7 узлов MongoDB + mongos + Redis + API)
docker compose up -d

# Проверка статуса всех контейнеров
docker compose ps
```

### 2. Инициализация кластера

```bash
./scripts/mongo-init.sh
```

### 3. Проверка работы

#### Веб-интерфейс
- **Основной API**: http://localhost:8080
- **Swagger документация**: http://localhost:8080/docs

#### Тестирование кеширования
```bash
# Первый запрос (медленный ~1 секунда)
time curl -s http://localhost:8080/helloDoc/users | head -20

# Второй запрос (быстрый <100мс из кеша)
time curl -s http://localhost:8080/helloDoc/users | head -20
```