# Mobile App Reverse-Engineering Questions

Answer the following questions based on the code generated during the exercise.

You may use the coding agent to help investigate the project, but you must inspect the source code and verify the answers yourself.

Whenever possible, mention the relevant files, classes, functions, or components.

---

## 1. Project Structure

What are the main parts of the project, and where can you find:

* UI/screens;
* data models;
* SQLite/database code;
* navigation;
* notification code?

Briefly describe how the project is organized.

### Resposta

O projeto está organizado na estrutura padrão do Flutter dentro do diretório `lib/`, dividindo as responsabilidades por camadas funcionais:

* **UI / Screens (`lib/screens/` e `lib/widgets/`):**
  * `lib/screens/task_list_screen.dart` (`TaskListScreen`): Tela principal com exibição da lista, barra de filtros, estados de *loading*, erro com *retry* e estado vazio.
  * `lib/screens/task_form_screen.dart` (`TaskFormScreen`): Formulário para criação e edição de tarefas, com seletores de vencimento.
  * `lib/screens/category_list_screen.dart` (`CategoryListScreen`): Tela para gerenciamento de categorias.
  * `lib/widgets/task_item_tile.dart` (`TaskItemTile`): Componente de cada item de tarefa da lista.
  * `lib/widgets/category_dialog.dart` (`CategoryDialog`): Diálogo modal para criação e edição de nomes de categoria.
* **Data Models (`lib/models/`):**
  * `lib/models/task.dart` (`Task`): Modelo imutável representando a tarefa (`id`, `title`, `description`, `completed`, `dueDateTime`, `createdAt`, `categoryId`).
  * `lib/models/category.dart` (`Category`): Modelo imutável representando a categoria (`id`, `name`).
* **SQLite / Database Code (`lib/database/` e `lib/repositories/`):**
  * `lib/database/app_database.dart` (`AppDatabase`): Classe Singleton responsável por inicializar o banco SQLite `mobile_todo.db`, habilitar `PRAGMA foreign_keys = ON;` e criar as tabelas `categories` e `tasks`.
  * `lib/repositories/task_repository.dart` (`TaskRepository`) e `lib/repositories/category_repository.dart` (`CategoryRepository`): Implementam todas as operações CRUD e conversões entre objetos e mapas SQLite.
* **Navigation (`lib/screens/` e `lib/main.dart`):**
  * Implementada de forma nativa e imperativa nos métodos de manipuladores de eventos dos widgets através da pilha de rotas do Flutter: `Navigator.push`, `Navigator.pop` e `MaterialPageRoute`. O arquivo `lib/main.dart` configura a `TaskListScreen` como a tela inicial (`home:`).
* **Notification Code (`lib/services/`):**
  * `lib/services/notification_service.dart` (`NotificationService`): Interface abstrata com a implementação real `LocalNotificationService` (utilizando `flutter_local_notifications` e `timezone`) e a implementação `FakeNotificationService` para testes. As permissões de sistema estão configuradas em `android/app/src/main/AndroidManifest.xml`.

---

## 2. Architecture and State

How is application state managed?

Explain how the UI is updated after an operation such as:

* creating a task;
* editing a task;
* marking a task as completed.

Does the project use any recognizable architectural pattern or state-management approach?

### Resposta

O estado da aplicação é gerenciado com o padrão reativo do Flutter utilizando as classes `ChangeNotifier` e a biblioteca `provider`.

As classes `TaskProvider` e `CategoryProvider` (`lib/providers/`) mantêm o estado dos dados em memória e notificam a interface gráfica através da chamada `notifyListeners()`. O `MultiProvider` configurado no `lib/main.dart` disponibiliza esses providers para toda a árvore de widgets.

A atualização da interface ocorre da seguinte forma após cada operação:

* **Criar uma tarefa:** O `TaskFormScreen` chama `context.read<TaskProvider>().createTask(newTask)`. O provider invoca o `TaskRepository.createTask`, que persiste no SQLite e retorna o ID autoincrementado. O provider adiciona a nova tarefa na lista em memória `_allTasks`, agenda a notificação (se houver vencimento futuro) e chama `notifyListeners()`. Os widgets envoltos por `Consumer<TaskProvider>` na `TaskListScreen` re-renderizam automaticamente.
* **Editar uma tarefa:** O `TaskFormScreen` chama `context.read<TaskProvider>().updateTask(updatedTask)`. O provider cancela a notificação anterior, atualiza no banco via `TaskRepository.updateTask`, atualiza a lista em memória, reagenda a notificação (se mantiver vencimento futuro) e executa `notifyListeners()`. A UI reflete a alteração imediatamente.
* **Marcar uma tarefa como concluída:** O usuário clica no `Checkbox` do `TaskItemTile`, invocando `context.read<TaskProvider>().toggleTaskCompletion(id, completed)`. O provider executa `TaskRepository.toggleTaskCompletion`, atualiza o campo `completed` na lista interna `_allTasks`, cancela a notificação pendente e executa `notifyListeners()`. O widget re-renderiza o título da tarefa com texto tachado (`TextDecoration.lineThrough`).

**Padrão Arquitetural:**
O projeto utiliza a arquitetura em camadas com fluxo de dados unidirecional:
`Screens / Widgets → Providers → Repositories → AppDatabase / SQLite`
A interface gráfica não acessa o banco SQLite diretamente.

---

## 3. SQLite Persistence

How is SQLite used in the application?

Identify:

* where the database is created;
* how tasks and categories are stored;
* where create, read, update, and delete operations are implemented.

### Resposta

O SQLite é utilizado para persistência de dados local off-line através do pacote `sqflite`.

* **Onde o banco é criado:** Em `lib/database/app_database.dart` na classe `AppDatabase`. O método `_initDatabase()` utiliza `openDatabase` criando o arquivo `mobile_todo.db`. O callback `_onConfigure` ativa a integridade referencial com `PRAGMA foreign_keys = ON;` e o callback `_onCreate` executa a criação das tabelas.
* **Como tarefas e categorias são armazenadas:**
  * Tabela `categories`:
    * `id INTEGER PRIMARY KEY AUTOINCREMENT`
    * `name TEXT NOT NULL`
  * Tabela `tasks`:
    * `id INTEGER PRIMARY KEY AUTOINCREMENT`
    * `title TEXT NOT NULL`
    * `description TEXT NULL`
    * `completed INTEGER NOT NULL` (`1` para verdadeiro, `0` para falso)
    * `due_date_time TEXT NULL` (armazenado em String ISO 8601)
    * `created_at TEXT NOT NULL` (armazenado em String ISO 8601)
    * `category_id INTEGER NULL` (`FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL`).
  * Na exclusão de uma categoria, o SQLite atribui automaticamente `NULL` ao `category_id` das tarefas vinculadas, mantendo as tarefas preservadas no banco.
* **Onde as operações CRUD são implementadas:**
  * `TaskRepository` (`lib/repositories/task_repository.dart`): métodos `createTask`, `getAllTasks`, `getTaskById`, `updateTask`, `toggleTaskCompletion` e `deleteTask`.
  * `CategoryRepository` (`lib/repositories/category_repository.dart`): métodos `createCategory`, `getAllCategories`, `getCategoryById`, `updateCategory` e `deleteCategory`.

---

## 4. Follow One Operation

Trace what happens when the user creates a new task.

Start from pressing **Save** and follow the execution until:

1. the task is stored in SQLite;
2. the task appears in the task list;
3. a notification is scheduled, if a due date exists.

Describe the main functions/components involved.

### Resposta

1. **Pressionar Salvar no `TaskFormScreen`:** O usuário preenche os campos e clica no botão "Criar Tarefa". O método `_saveTask()` aciona a validação `_formKey.currentState.validate()`, garantindo que o título não esteja vazio.
2. **Instanciação do Objeto:** Um objeto `Task` é criado com o título, descrição opcional, categoria selecionada, status `completed`, data de criação `createdAt: DateTime.now()` e prazo opcional `dueDateTime`.
3. **Chamada do Provider:** A tela invoca `context.read<TaskProvider>().createTask(newTask)`.
4. **Execução no `TaskProvider`:** O `TaskProvider` (`lib/providers/task_provider.dart`) define `_isLoading = true`, `_errorMessage = null` e chama `notifyListeners()`.
5. **Chamada do Repositório:** O provider invoca `TaskRepository.createTask(task)`.
6. **Inserção no SQLite:** O `TaskRepository` converte o objeto em mapa via `_toMap` e executa `db.insert('tasks', map)`. O banco SQLite insere o registro e retorna o ID autoincrementado.
7. **Retorno do Objeto Persistido:** O repositório retorna o objeto com o ID atrelado (`task.copyWith(id: id)`).
8. **Atualização da Memória:** O `TaskProvider` adiciona a nova tarefa no topo da lista interna `_allTasks`.
9. **Agendamento da Notificação:** O `TaskProvider` verifica se `createdTask.dueDateTime != null`, se o vencimento é futuro (`isAfter(DateTime.now())`) e se a tarefa não está concluída (`!createdTask.completed`). Atendidas as condições, chama `_notificationService.scheduleNotification(id: createdTask.id!, title: 'Lembrete de Tarefa', body: createdTask.title, scheduledDate: createdTask.dueDateTime!)`.
10. **Finalização do Provider:** O `TaskProvider` define `_isLoading = false` e executa `notifyListeners()`.
11. **Retorno e Renderização na Lista:** A `TaskFormScreen` executa `Navigator.pop(context)`. A `TaskListScreen`, inscrita no `TaskProvider` via `Consumer<TaskProvider>`, re-renderiza exibindo a nova tarefa imediatamente no `TaskItemTile`.

---

## 5. Navigation

How does navigation between screens work?

In particular:

* how does the app navigate from the task list to the task editor?
* when editing a task, what information is passed between screens?

For example: task ID, full object, shared state, or another approach.

### Resposta

A navegação entre telas funciona através da pilha de rotas nativa e imperativa do Flutter, utilizando os comandos `Navigator.push`, `Navigator.pop` e a classe `MaterialPageRoute`.

* **Navegação da Lista para o Editor:**
  * **Criação de nova tarefa:** No botão flutuante (`FloatingActionButton`) da `TaskListScreen` (`lib/screens/task_list_screen.dart`), o aplicativo executa `Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskFormScreen()))`.
  * **Edição de tarefa existente:** Ao clicar em um item da lista (`TaskItemTile` em `lib/widgets/task_item_tile.dart`), o aplicativo executa `Navigator.push(context, MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)))`.
* **Informações passadas entre telas na edição:**
  * **Modo Criação:** Nenhum parâmetro é enviado no construtor (`TaskFormScreen()`), mantendo a propriedade `widget.task` como `null`.
  * **Modo Edição:** O objeto completo `Task` é passado diretamente como parâmetro para o construtor da tela (`TaskFormScreen(task: task)`). O formulário utiliza os dados desse objeto para preencher os campos iniciais. Ao salvar a edição, o formulário invoca `taskProvider.updateTask`, utilizando `widget.task!.copyWith(...)` para preservar o `id` e a data de criação `createdAt` originais.

---

## 6. Notifications

How are task reminders implemented?

Explain:

* how a notification is scheduled;
* how it is associated with a task;
* what happens when the due date changes;
* what happens when the task is completed or deleted.

### Resposta

Os lembretes são implementados através da classe `LocalNotificationService` (`lib/services/notification_service.dart`), que encapsula os pacotes `flutter_local_notifications` e `timezone`. As permissões no Android estão configuradas em `android/app/src/main/AndroidManifest.xml` (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`). Se o usuário negar permissões, a exceção é capturada e a aplicação continua funcionando normalmente sem interromper o CRUD.

* **Como a notificação é agendada:** O método `scheduleNotification` verifica se a `scheduledDate` é futura (`isAfter(DateTime.now())`). Em caso positivo, converte a data para `tz.TZDateTime.from(scheduledDate, tz.local)` e executa `_plugin.zonedSchedule` configurado com alta prioridade (`AndroidScheduleMode.exactAllowWhileIdle`).
* **Como é associada à tarefa:** O ID da tarefa no SQLite (`task.id!`) é reutilizado diretamente como o identificador único da notificação (`notificationId = task.id!`).
* **O que acontece quando a data de vencimento muda:** No método `TaskProvider.updateTask`, o provider cancela primeiro a notificação antiga (`_notificationService.cancelNotification(task.id!)`). Se o novo vencimento for no futuro e a tarefa não estiver concluída, agenda uma nova notificação com a nova data. Se o vencimento for removido (`clearDueDateTime`), a notificação permanece cancelada.
* **O que acontece quando a tarefa é concluída ou excluída:**
  * **Concluída (`toggleTaskCompletion` com `completed == true`):** O provider chama `_notificationService.cancelNotification(id)`. Se reaberta (`completed == false`) com vencimento futuro, o provider reagenda a notificação.
  * **Excluída (`deleteTask`):** O provider cancela a notificação (`_notificationService.cancelNotification(id)`) antes de deletar a tarefa do banco SQLite.

---

## 7. Agent Decisions

Identify at least **two important decisions made by the coding agent that were not explicitly specified in the assignment**.

Examples:

* architecture;
* libraries;
* state-management strategy;
* navigation approach;
* SQLite abstraction;
* project structure.

For each one, explain what the agent chose.

### Resposta

#### Decisão 1 — Abstração do Serviço de Notificações com `FakeNotificationService` para Testes
1. **O que foi escolhido:** O agente criou a interface abstrata `NotificationService` em `lib/services/notification_service.dart`, fornecendo a implementação real `LocalNotificationService` e a classe mock em memória `FakeNotificationService`.
2. **Como aparece no projeto:** O `LocalNotificationService` é instanciado no `main.dart`, enquanto o `FakeNotificationService` é injetado nas suítes de teste de unidade (`test/providers/task_provider_test.dart` e `test/services/notification_service_test.dart`).
3. **Por que foi útil:** Permitiu testar todo o ciclo de vida de agendamento, cancelamento e reagendamento de notificações em testes automatizados sem depender de plugins nativos nem de emuladores do Android.

#### Decisão 2 — Gerenciamento de Filtros em Memória Separado do Banco de Dados
1. **O que foi escolhido:** O agente manteve a lista de tarefas salvas (`_allTasks`) separada da lista visível (`tasks`), calculando os filtros de status (`TaskStatusFilter`) e categoria em tempo de execução na memória do `TaskProvider`.
2. **Como aparece no projeto:** O getter `tasks` em `lib/providers/task_provider.dart` aplica a filtragem em memória na coleção `_allTasks`.
3. **Por que foi útil:** Tornou a alternância de filtros na `TaskListScreen` instantânea para o usuário, evitando consultas SQL desnecessárias no SQLite a cada mudança de filtro.

#### Decisão 3 — Encapsulamento do Estado com `UnmodifiableListView`
1. **O que foi escolhido:** As listas internas mantidas pelos Providers (`_allTasks` e `_categories`) são expostas aos widgets como coleções imutáveis do tipo `UnmodifiableListView`.
2. **Como aparece no projeto:** Os getters `allTasks`, `tasks` e `categories` retornam `UnmodifiableListView(...)`.
3. **Por que foi útil:** Impediu que widgets de interface alterem as coleções diretamente na memória sem passar pelos métodos formais do Provider, garantindo a execução da persistência no SQLite e a emissão de `notifyListeners()`.

---

## 8. BUILD_LOG Analysis

Using `BUILD_LOG.md`, identify:

* one problem or bug encountered during development;
* how the agent attempted to solve it;
* whether the first solution worked;
* what was eventually done.

Then answer:

**What did the build log help you understand that would have been harder to discover by looking only at the final code?**

### Resposta

* **Problema:**
  Na Entry 006, durante a primeira execução da suíte de testes do repositório no ambiente Windows, ocorreu a exceção `SqliteException(14): unable to open database file` ao tentar abrir o banco de dados de teste concatenando o nome do caminho em memória como `":memory:_test.db"`.
* **Primeira tentativa:**
  O agente tentou passar uma string concatenada com o sufixo do teste para criar o caminho em memória no método de abertura do banco.
* **Resultado da primeira tentativa:**
  A primeira tentativa falhou porque o caractere dois-pontos (`:`) em `":memory:"` é um caractere reservado e inválido em caminhos de arquivo do sistema operacional Windows.
* **Solução final:**
  O agente ajustou os arquivos de teste (`test/repositories/category_repository_test.dart` e `test/repositories/task_repository_test.dart`) para passar a instância de banco aberta diretamente por `AppDatabase.openTestDatabase(dbPath: inMemoryDatabasePath, databaseFactory: databaseFactoryFfi)` para o construtor do repositório (`CategoryRepository(db: testDb)`), fechando a conexão em `tearDown()` com `testDb.close()`.

**O que o BUILD_LOG ajudou a entender que seria mais difícil descobrir olhando apenas para o código final?**
O `BUILD_LOG.md` revelou peculiaridades de compatibilidade de plataforma e decisões de design tomadas em resposta a erros de execução que não deixam rastro no código-fonte limpo final. Ao inspecionar somente o código final dos testes, vê-se apenas a injeção do banco aberto no construtor do repositório. O log de construção explicou a falha inicial com caminhos no Windows, as tentativas de correção, a justificativa exata para a estrutura de injeção de dependência adotada nos testes e os ajustes de avisos do linter realizados durante o desenvolvimento.
