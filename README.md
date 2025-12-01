# Лабораторная работа 4

- Студент: `Чураков Александр Алексеевич`
- Группа: `P3331`
- ИСУ: `409856`
- Функциональный язык: `Elixir`

---

**Распределённое in-memory хранилище, использующее алгоритм Raft consensus.**

---

## **Как это работает**

1. Запускается кластер из N узлов.
2. Внутри создаются несколько consensus groups.
3. Каждый group — это свой Raft-кластер.
4. Когда приходит команда `put("x", 42)`:
   - выбирается группа для ключа "x";
   - запрос идёт на лидера этой группы;
   - лидер пишет запись в лог;
   - реплицирует на фолловеров;
   - после подтверждения — state machine применяет команду;
   - значение "x" = 42 становится доступно для чтения.

---

### **Узлы Raft**

**Как выглядит цикл работы:**

1. Узлы запускаются как `Follower`.
2. Если долго нет heartbeat — узел становится `Candidate`.
3. Выборы -> один узел становится `Leader`.
4. Все клиентские команды записываются в лог через лидера.
5. Лидер реплицирует записи на остальных.
6. После подтверждения большинства запись считается применённой.

---

# **Описание использования через TUI**

Был добавлен простой консольный интерфейс, позволяющий управлять распределённой базой данных без необходимости вручную вызывать функции в интерпретаторе `iex`. ТUI реализован как Mix-задача:

```
mix raft
```

После запуска пользователь попадает в интерактивное меню:

```
1) Connect to node
2) Activate this node
3) Create consensus group
4) Query group
5) Command group
6) Exit
```

## **Основные действия**

### **1) Подключение к другому узлу кластера**

Позволяет выполнить команду `Node.connect/1`, чтобы связать локальный узел Elixir с другим нодом Erlang/Elixir:

```
> 1
Enter node (example: 1@laptop): 1@laptop
Connected: true
```

Это позволяет строить распределённый кластер из нескольких терминалов.

---

### **2) Активация узла в зоне**

Каждый узел должен быть активирован с привязкой к зоне (логическая группа, например zone1/zone2):

```
> 2
Enter zone name (e.g. zone1): zone1
Node activated.
```

Активация сообщает системе, что этот узел готов принимать на себя роли реплик Raft-групп.

---

### **3) Создание новой группы консенсуса**

Позволяет создать Raft-группу с требуемым числом реплик:

```
> 3
Group name (atom): cons1
Members count: 3
Group cons1 created.
```

При этом:

- выбирается лидер группы
- остальные узлы автоматически становятся follower
- создаётся внутренний `RaftNode` для группы на каждом узле

---

### **4) Чтение значения из Raft-группы (Query)**

TUI вызывает `RaftDB.ConsensusGroups.GroupApplication.query/2`, что выполняет **консистентный read**:

```
> 4
Group name: cons1
Query (e.g. :get): :get
Value: 0
```

---

### **5) Выполнение записи (Command)**

Команда отправляется только лидеру, проходит через Raft:

```
> 5
Group name: cons1
Command (e.g. {:inc} or {:set, 10}): {:inc}
OK. New value: 1
```

---

# **Ключевые моменты устройства базы данных**

Ниже перечислены основные архитектурные элементы распределённой базы данных на основе Raft.

---

## **Узлы**

Каждый процесс Erlang/Elixir, запущенный с именем, является узлом.
Узлы могут:

- соединяться в кластер через `Node.connect/1`
- управляться через `GroupApplication`
- содержать несколько Raft-групп одновременно

---

## **2. Зоны**

Каждый активированный узел принадлежит _зоне_:

```
activate("zone1")
```

Зоны используются для распределения нагрузки:

- узлы одной зоны обычно хранят реплики одних и тех же групп
- при отключении узлов балансировка учитывает зоны

Это механизм топологической группировки.

---

## **Группы консенсуса**

Каждая группа представляет собой **независимое состояние** (например числовой счётчик), которое реплицируется на нескольких узлах.

Например:

```
cons1 → 3 реплики
cons2 → 5 реплик
```

У групп свой собственный лидер, журнал и FSM.

---

## **RaftNode**

Каждый RaftNode — это процесс `gen_statem` с тремя состояниями:

- **follower**
- **candidate**
- **leader**

Функции RaftNode:

1. принять команду от клиента
2. записать запись в лог
3. отправить AppendEntries всем follower
4. дождаться большинства
5. применить команду к стейт-машине
6. вернуть результат клиенту

Raft обеспечивает:

- линеаризуемость
- устойчивость к сбоям
- согласованность между узлами

---

## **RPCServer**

Промежуточный слой, который обрабатывает:

- AppendEntries
- RequestVote
- снапшоты
- синхронизацию журналов
- передачу команд и запросов

---

## **StateMachine**

Пользователь определяет свою стейт-машину:

```elixir
defmodule JustAnInt do
  @behaviour RaftDB.Raft.StateMachine.Statable
  def new(), do: 0
  def command(i, :inc), do: {i, i + 1488}
  def query(i, :get), do: i
end
```

Raft гарантирует, что:

- **command** вызывается _одинаково на всех репликах_
- **query** вызывается только локально на лидере

---

## **Лог, снапшоты и восстановление**

Используется:

- журнал операций (`log_*`)
- снапшоты (`snapshot_*`)

Механизм:

- при переполнении лог компактизируется
- снапшот хранит актуальное состояние
- при восстановлении из файлов состояние поднимается полностью автоматически

---

## **Supervisor Tree**

Приложение запускает несколько воркеров:

- **ConsensusMemberSupervisor**
- **Cluster Manager**
- **NodeReconnect**
- **LeaderPidCacheRefresher**
- **ProcessAndDiskLogIndexInspector**

Они обеспечивают:

- восстановление после падений
- очистку от мёртвых процессов
- обновление кешей
- обработку отключений узлов

---

## **LeaderPidCache**

Кеш хранит PID лидера каждой группы.
Это позволяет:

- быстро обращаться к лидеру
- снижать число сетевых запросов

---

#### Использование через интерпреатор

Предположим, что у нас есть 4 ноды в кластере:

```bash
$ iex --sname 1 -S mix
iex(1@laptop)>

$ iex --sname 2 -S mix
iex(2@laptop)> Node.connect(:"1@laptop")

$ iex --sname 3 -S mix
iex(3@laptop)> Node.connect(:"1@laptop")

$ iex --sname 4 -S mix
iex(4@laptop)> Node.connect(:"1@laptop")
```

Загрузим модуль, реализующий `RaftDB.Raft.StateMachine.Statable` поведение на нодах:

```elixir
  defmodule JustAnInt do
    @behaviour RaftDB.Raft.StateMachine.Statable
    def new, do: 0
    def command(i, {:set, j}), do: {i, j}
    def query(i, :get), do: i
  end
```

Активируем зоны `RaftDB.ConsensusGroups.GroupApplication.activate/1`:

```elixir
iex(1@laptop)> RaftDB.ConsensusGroups.GroupApplication.activate("zone1")

iex(2@laptop)> RaftDB.ConsensusGroups.GroupApplication.activate("zone2")

iex(3@laptop)> RaftDB.ConsensusGroups.GroupApplication.activate("zone1")

iex(4@laptop)> RaftDB.ConsensusGroups.GroupApplication.activate("zone2")
```

Создадим 5 консенсусных групп, каждая реплицирует число и имеет трех членов:

```elixir
iex(1@laptop)> config = RaftDB.Raft.Node.make_config(JustAnInt)
iex(1@laptop)> RaftDB.ConsensusGroups.GroupApplication.add_consensus_group(:consensus1, 3, config)
iex(1@laptop)> RaftDB.ConsensusGroups.GroupApplication.add_consensus_group(:consensus2, 3, config)
iex(1@laptop)> RaftDB.ConsensusGroups.GroupApplication.add_consensus_group(:consensus3, 3, config)
```

Теперь можем вызывать команды:

```elixir
iex(1@laptop)> RaftDB.ConsensusGroups.GroupApplication.query(:consensus1, :get)
{:ok, 0}

iex(3@laptop)> RaftDB.ConsensusGroups.GroupApplication.query(:consensus1, :get)
{:ok, 1}
```

Консенсус продолжает работать даже если один из членов перестал работать:

```elixir
iex(3@laptop)> :gen_statem.stop(:baz)
iex(1@laptop)> RaftDB.ConsensusGroups.GroupApplication.query(:consensus1, :get)
{:ok, 1}
```

## Выводы

В ходе выполнения лабораторной работы я познакомился с алгоритмом консенсуса Raft и реализовал его с нуля на Elixir, поработал с кластеризацией и node-to-node коммуникацией в ErlangVM, узнал много нового об OTP и мониторинге Elixir приложений, научился тестировать распределенные Elixir приложения.
