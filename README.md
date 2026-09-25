# Projeto Mobile — To-Do Flutter

## Descrição
Aplicativo móvel de gerenciamento de tarefas desenvolvido em Flutter e Dart para uma atividade acadêmica. O objetivo do aplicativo é permitir a organização eficiente de tarefas diárias, oferecendo cadastro, edição, categorização, filtragem reativa em memória, definição de prazos de vencimento e agendamentos de notificações locais com suporte a armazenamento off-line persistente.

---

## Funcionalidades
* **CRUD de Tarefas:** Criação, leitura, atualização e exclusão de tarefas.
* **Conclusão e Reabertura:** Alternância simples de status de conclusão (pendente / concluída) diretamente na listagem ou no formulário.
* **Gerenciamento de Categorias:** Criação, edição/renomeação e exclusão de categorias.
* **Persistência Relacional com Integridade:** Regra `ON DELETE SET NULL` no SQLite; ao excluir uma categoria, as tarefas associadas são mantidas no sistema e passam a ter `categoryId = null`.
* **Filtros Reativos em Memória:**
  * Por Status: *Todas*, *Pendentes*, *Concluídas*.
  * Por Categoria: *Todas categorias* ou seleção de uma categoria específica.
  * Combinação dinâmica dos dois filtros em tempo de execução sem alterar os dados salvos no SQLite.
* **Data e Hora de Vencimento (`dueDateTime`):**
  * Seleção opcional usando componentes nativos (`showDatePicker` e `showTimePicker`).
  * Visualização da data/hora formatada (`dd/MM/yyyy HH:mm`) e opção de remoção do vencimento.
  * Destaque visual em vermelho para tarefas pendentes em atraso.
* **Notificações Locais Reativas:**
  * Agendamento automático para tarefas pendentes com vencimento no futuro via `flutter_local_notifications`.
  * Cancelamento imediato ao concluir, excluir ou remover o vencimento.
  * Reagendamento automático ao alterar o vencimento ou reabrir uma tarefa pendente.
  * Funcionamento resiliente mesmo caso as permissões do sistema sejam negadas.
* **Tratamento de Erros e Estados da Interface:** Telas reativas com suporte a estados de *loading*, mensagens de erro com opção de *retry* e estados vazios amigáveis.

---

## Tecnologias
* **Linguagem:** Dart (versão ^3.11.0)
* **Framework:** Flutter SDK
* **Gerenciamento de Estado:** Provider (`^6.1.5+1`) & `ChangeNotifier`
* **Banco de Dados Local:** SQLite via `sqflite` (`^2.4.2+1`) e `path` (`^1.9.1`)
* **Notificações Locais:** `flutter_local_notifications` (`^22.3.1`) e `timezone` (`^0.10.0`)
* **Execução de Testes em Memória:** `sqflite_common_ffi` (`^2.4.0+3`) e `flutter_test`

---

## Arquitetura
A arquitetura do aplicativo segue o fluxo unidirecional em camadas bem definidas e desacopladas:

```text
Screens / UI Widgets
         ↓
Provider (ChangeNotifier)
         ↓
   Repositories
         ↓
   AppDatabase
         ↓
  SQLite Database
```

### Componentes Principais:
* **`models/` (`Task`, `Category`):** Classes de domínio puras com imutabilidade e métodos utilitários (`copyWith`, `operator ==`, `hashCode`).
* **`database/` (`AppDatabase`):** Singleton para inicialização e configuração do banco SQLite, ativação de `PRAGMA foreign_keys = ON;` e abertura de banco em memória para testes.
* **`repositories/` (`TaskRepository`, `CategoryRepository`):** Abstração de acesso ao banco com conversões centralizadas `Model ↔ Map` e validações de dados. A interface gráfica não acessa o banco de dados diretamente.
* **`providers/` (`TaskProvider`, `CategoryProvider`):** Gerenciadores de estado reativos baseados em `ChangeNotifier`. Encapsulam o estado e expõem coleções imutáveis (`UnmodifiableListView`).
* **`services/` (`NotificationService`):** Camada de isolamento do plugin de notificações locais com implementação real (`LocalNotificationService`) e versão fake para testes (`FakeNotificationService`).
* **`screens/` (`TaskListScreen`, `TaskFormScreen`, `CategoryListScreen`):** Telas da aplicação com fluxo de navegação nativa (`Navigator.push`, `Navigator.pop`, `MaterialPageRoute`).
* **`widgets/` (`TaskItemTile`, `CategoryDialog`):** Componentes reutilizáveis de interface.

---

## Banco de Dados
O aplicativo utiliza o banco de dados SQLite salvo localmente como `mobile_todo.db`.

### Esquema das Tabelas

#### `categories`
* `id` (`INTEGER PRIMARY KEY AUTOINCREMENT`): Identificador único da categoria.
* `name` (`TEXT NOT NULL`): Nome da categoria.

#### `tasks`
* `id` (`INTEGER PRIMARY KEY AUTOINCREMENT`): Identificador único da tarefa.
* `title` (`TEXT NOT NULL`): Título da tarefa.
* `description` (`TEXT NULL`): Detalhamento opcional.
* `completed` (`INTEGER NOT NULL`): Booleano (`0` para falsa, `1` para verdadeira).
* `due_date_time` (`TEXT NULL`): Data e hora de vencimento em formato ISO 8601 (`String`).
* `created_at` (`TEXT NOT NULL`): Data e hora de criação em formato ISO 8601 (`String`).
* `category_id` (`INTEGER NULL`): Chave estrangeira para `categories.id` com a regra `FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL`.

---

## Notificações Locais
A gestão de notificações é realizada pelo `LocalNotificationService`, centralizando as operações de inicialização e agendamento.
* **Permissões:** Solicitadas ao usuário de forma transparente na plataforma Android (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`).
* **Comportamento Resiliente:** Caso o usuário negue permissões ou o dispositivo bloqueie alarmes exatos, as operações de salvamento e edição da tarefa continuam funcionando normalmente.
* **Ciclo de Vida Integrado:** O agendamento, cancelamento e reagendamento de notificações é tratado automaticamente nos métodos CRUD do `TaskProvider`.

---

## Como Executar

### Pré-requisitos
* Flutter SDK configurado
* Dispositivo Android (Emulador ou Físico) ou ambiente desktop para desenvolvimento

### Passos para Execução
1. Clonar o repositório e acessar a pasta do projeto:
   ```bash
   cd todo-list-dart
   ```
2. Instalar as dependências do projeto:
   ```bash
   flutter pub get
   ```
3. Executar a análise estática do código:
   ```bash
   flutter analyze
   ```
4. Executar a suíte completa de testes automatizados:
   ```bash
   flutter test
   ```
5. Executar o aplicativo em um dispositivo ou emulador conectado:
   ```bash
   flutter run
   ```
6. Gerar o pacote de instalação APK para Android:
   ```bash
   flutter build apk
   ```
   * O arquivo APK compilado estará disponível em `build/app/outputs/flutter-apk/app-release.apk`.

---

## Estrutura do Projeto
```text
lib/
├── database/
│   └── app_database.dart
├── models/
│   ├── category.dart
│   └── task.dart
├── providers/
│   ├── category_provider.dart
│   └── task_provider.dart
├── repositories/
│   ├── category_repository.dart
│   └── task_repository.dart
├── screens/
│   ├── category_list_screen.dart
│   ├── task_form_screen.dart
│   └── task_list_screen.dart
├── services/
│   └── notification_service.dart
├── widgets/
│   ├── category_dialog.dart
│   └── task_item_tile.dart
└── main.dart

test/
├── database_test.dart
├── models_test.dart
├── providers/
│   ├── category_provider_test.dart
│   └── task_provider_test.dart
├── repositories/
│   ├── category_repository_test.dart
│   └── task_repository_test.dart
├── screens/
│   ├── category_list_screen_test.dart
│   ├── task_form_screen_test.dart
│   └── task_list_screen_test.dart
└── services/
    └── notification_service_test.dart
```

---

## Testes Automatizados
O projeto conta com uma suíte abrangente de **81 testes automatizados**, cobrindo todas as camadas da aplicação:

* **Modelos de Domínio (`test/models_test.dart`):** 9 testes.
* **Infraestrutura SQLite (`test/database_test.dart`):** 4 testes.
* **Repositórios (`test/repositories/`):** 22 testes.
* **Providers de Estado (`test/providers/`):** 29 testes.
* **Serviço de Notificações (`test/services/`):** 5 testes.
* **Telas e Widgets (`test/screens/`):** 12 testes.

---

## Observações
* Todas as notificações geradas pelo aplicativo são locais e dependem apenas do relógio e sistema de alarmes do dispositivo.
* Os dados são armazenados localmente no banco SQLite (`mobile_todo.db`), garantindo funcionamento off-line completo sem necessidade de internet.
* A negação de permissões de notificação não afeta a criação, edição ou exclusão de tarefas.
