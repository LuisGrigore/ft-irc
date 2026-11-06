# Implementation Plan

Traceability plan for the **ft_irc** IRC server project, derived from:

- `en.subject.pdf` (project requirements, Chapter IV — Mandatory Part)
- `docs/diagrams/class/irc_clients.mmd`
- `docs/diagrams/class/irc_network_layer_pull.mmd`
- `docs/diagrams/class/irc_commands.mmd`
- `docs/diagrams/class/irc_channels.mmd`

Each element has a unique traceability ID:

| Prefix | Meaning |
|--------|---------|
| FEAT   | Independent feature (user-facing capability) |
| T      | Task (implementation step, child of a feature) |
| AC     | Acceptance criterion (verifiable outcome) |

---

## 1. Features Table

| ID | Name | Short Description | Related Elements |
|----|------|-------------------|------------------|
| FEAT-001 | Core IRC Service & Client Management | IRCService orchestrator, Client entity, ClientManager, NickManager registries, registration flow (PASS/NICK/USER) | `irc_clients.mmd` |
| FEAT-002 | Network Layer & Socket I/O | SocketService interface, TickResult, SocketServer, poll() event loop, non-blocking I/O | `irc_network_layer_pull.mmd` |
| FEAT-003 | Command Parsing & Dispatching | IRCParser, IRCMessage, CommandDispatcher, CommandHandler chain, CommandFactory, CommandContext, ReplyFormatter | `irc_commands.mmd` |
| FEAT-004 | Channel Management | ChannelManager registry, Channel entity, JOIN/PART, channel message broadcasting | `irc_channels.mmd` |
| FEAT-005 | Channel Modes & Operator Commands | ChannelMode strategies (i, t, k, o, l), KICK, INVITE, TOPIC, MODE commands | `irc_channels.mmd` |
| FEAT-006 | Private Messages & Notice | PRIVMSG and NOTICE commands between clients | `irc_commands.mmd` |
| FEAT-007 | Robustness & Edge Cases | Input buffer aggregation, graceful disconnection, signal handling, no crashes | Subject Chapter IV |
| FEAT-008 | Build System & Project Skeleton *(deferred)* | Makefile rules, C++98 flags, executable name `ircserv`, argument parsing *(deferred — use existing build system for development, adjust later for 42 guidelines)* | Subject Chapter IV |

---

## 2. Tasks Table

| ID | Description | TDD Step | Feature ID | Related Elements |
|----|-------------|----------|------------|------------------|
| T-001 | Write unit tests for `Client` getters/setters (nick, username, realname, hostname, authenticated, registered, closing) | Red | FEAT-001 | `irc_clients.mmd` |
| T-002 | Implement `Client` class fields and getter/setter methods | Green | FEAT-001 | `irc_clients.mmd` |
| T-003 | Refactor `Client` for C++98 compliance and warning-free compilation | Refactor | FEAT-001 | `irc_clients.mmd` |
| T-004 | Write unit tests for `Client` buffer operations (`appendInput`, `popLine`, `appendOutput`, `takeOutput`) | Red | FEAT-001 | `irc_clients.mmd` |
| T-005 | Implement `Client` input/output buffer methods | Green | FEAT-001 | `irc_clients.mmd` |
| T-006 | Refactor `Client` buffer logic | Refactor | FEAT-001 | `irc_clients.mmd` |
| T-007 | Write unit tests for `ClientManager` (add, remove, find by fd/nick, list) | Red | FEAT-001 | `irc_clients.mmd` |
| T-008 | Implement `ClientManager` registry (map fd → Client*) | Green | FEAT-001 | `irc_clients.mmd` |
| T-009 | Refactor `ClientManager` ownership semantics | Refactor | FEAT-001 | `irc_clients.mmd` |
| T-010 | Write unit tests for `NickManager` (reserve, release, isAvailable, isValid) | Red | FEAT-001 | `irc_clients.mmd` |
| T-011 | Implement `NickManager` registry (set of nicks) | Green | FEAT-001 | `irc_clients.mmd` |
| T-012 | Refactor `NickManager` validation logic | Refactor | FEAT-001 | `irc_clients.mmd` |
| T-013 | Write unit tests for `IRCService` lifecycle (onClientConnected/onClientData/onClientDisconnected/tick) | Red | FEAT-001 | `irc_clients.mmd`, `irc_network_layer_pull.mmd` |
| T-014 | Implement `IRCService` orchestrator (password, dirtyClients sets, tick method) | Green | FEAT-001 | `irc_clients.mmd`, `irc_network_layer_pull.mmd` |
| T-015 | Refactor `IRCService` orchestration logic | Refactor | FEAT-001 | `irc_clients.mmd` |
| T-016 | Write integration tests for registration flow (PASS → NICK → USER → registered) | Red | FEAT-001 | Subject Chapter IV |
| T-017 | Implement registration command handling (`PASS`, `NICK`, `USER`) | Green | FEAT-001 | Subject Chapter IV |
| T-018 | Refactor registration flow state machine | Refactor | FEAT-001 | Subject Chapter IV |
| T-019 | Write unit tests for `TickResult` struct fields and default values | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-020 | Implement `TickResult` struct | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-021 | Refactor `TickResult` for copy/move semantics | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-022 | Write unit tests for `SocketService` interface contract (pure virtual methods) | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-023 | Implement `SocketService` pure abstract interface | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-024 | Refactor `SocketService` interface | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-025 | Write integration tests for `SocketServer` listen/accept lifecycle | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-026 | Implement `SocketServer` class (port, listenFd, running, pollFds, pendingOutput, closingFds) | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-027 | Refactor `SocketServer` socket setup (`socket`, `bind`, `listen`, `setsockopt`, `fcntl` non-blocking) | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-028 | Write integration tests for single `poll()` event loop handling listen/read/write | Red | FEAT-002 | Subject Chapter IV |
| T-029 | Implement event loop with single `poll()` call | Green | FEAT-002 | Subject Chapter IV |
| T-030 | Refactor event loop to avoid blocking and `errno` checks | Refactor | FEAT-002 | Subject Chapter IV |
| T-031 | Write integration tests for client connect/disconnect via `accept`/`close` | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-032 | Implement `accept` for new connections and fd registration in `pollFds` | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-033 | Refactor connection/disconnection cleanup | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-034 | Write unit tests for `IRCService` implementing `SocketService::tick` | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-035 | Wire `IRCService` to implement `SocketService` interface | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-036 | Refactor `IRCService::tick` to return populated `TickResult` | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-037 | Write unit tests for `IRCMessage` parsing fields | Red | FEAT-003 | `irc_commands.mmd` |
| T-038 | Implement `IRCMessage` data class | Green | FEAT-003 | `irc_commands.mmd` |
| T-039 | Refactor `IRCMessage` field accessors | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-040 | Write unit tests for `IRCParser` (valid and malformed lines) | Red | FEAT-003 | `irc_commands.mmd` |
| T-041 | Implement `IRCParser` utility (`parseLine`, `extractPrefix`, `extractCommand`, `extractParams`) | Green | FEAT-003 | `irc_commands.mmd` |
| T-042 | Refactor `IRCParser` for partial-line handling | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-043 | Write unit tests for `CommandFactory` (register/create by name) | Red | FEAT-003 | `irc_commands.mmd` |
| T-044 | Implement `CommandFactory` | Green | FEAT-003 | `irc_commands.mmd` |
| T-045 | Refactor `CommandFactory` registration map | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-046 | Write unit tests for `Command` interface (pure virtual methods) | Red | FEAT-003 | `irc_commands.mmd` |
| T-047 | Implement `Command` abstract interface | Green | FEAT-003 | `irc_commands.mmd` |
| T-048 | Refactor `Command` interface | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-049 | Write unit tests for `CommandHandler` chain propagation | Red | FEAT-003 | `irc_commands.mmd` |
| T-050 | Implement `CommandHandler` chain interface | Green | FEAT-003 | `irc_commands.mmd` |
| T-051 | Refactor `CommandHandler` chain links | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-052 | Write unit tests for chain handlers (`RegistrationCheckHandler`, `ParamCheckHandler`, `ExecutionHandler`) | Red | FEAT-003 | `irc_commands.mmd` |
| T-053 | Implement chain handlers | Green | FEAT-003 | `irc_commands.mmd` |
| T-054 | Refactor handler logic for registration/param/execution separation | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-055 | Write integration tests for `CommandDispatcher` dispatch flow | Red | FEAT-003 | `irc_commands.mmd` |
| T-056 | Implement `CommandDispatcher` (chain ownership, `dispatchNext`, context creation) | Green | FEAT-003 | `irc_commands.mmd` |
| T-057 | Refactor `CommandDispatcher` parser/factory integration | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-058 | Write unit tests for `CommandContext` (`send`/`disconnect` helpers) | Red | FEAT-003 | `irc_commands.mmd` |
| T-059 | Implement `CommandContext` | Green | FEAT-003 | `irc_commands.mmd` |
| T-060 | Refactor `CommandContext` output appending | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-061 | Write unit tests for `ReplyFormatter` reply strings | Red | FEAT-003 | `irc_commands.mmd` |
| T-062 | Implement `ReplyFormatter` | Green | FEAT-003 | `irc_commands.mmd` |
| T-063 | Refactor `ReplyFormatter` formatting logic | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-064 | Write unit tests for `ChannelManager` (create/find/destroy/list) | Red | FEAT-004 | `irc_channels.mmd` |
| T-065 | Implement `ChannelManager` registry (map name → Channel*) | Green | FEAT-004 | `irc_channels.mmd` |
| T-066 | Refactor `ChannelManager` channel lifecycle | Refactor | FEAT-004 | `irc_channels.mmd` |
| T-067 | Write unit tests for `Channel` member/operator management | Red | FEAT-004 | `irc_channels.mmd` |
| T-068 | Implement `Channel` class (name, topic, creator, members/operators/invited sets) | Green | FEAT-004 | `irc_channels.mmd` |
| T-069 | Refactor `Channel` membership logic | Refactor | FEAT-004 | `irc_channels.mmd` |
| T-070 | Write integration tests for `JOIN` command | Red | FEAT-004 | Subject Chapter IV |
| T-071 | Implement `JOIN` command (create channel if needed, forward join) | Green | FEAT-004 | Subject Chapter IV |
| T-072 | Refactor `JOIN` notification broadcasting | Refactor | FEAT-004 | Subject Chapter IV |
| T-073 | Write integration tests for `PART` command | Red | FEAT-004 | Subject Chapter IV |
| T-074 | Implement `PART` command (leave channel, destroy if empty) | Green | FEAT-004 | Subject Chapter IV |
| T-075 | Refactor `PART` cleanup logic | Refactor | FEAT-004 | Subject Chapter IV |
| T-076 | Write integration tests for channel message broadcasting | Red | FEAT-004 | Subject Chapter IV |
| T-077 | Implement channel message forwarding to all members | Green | FEAT-004 | Subject Chapter IV |
| T-078 | Refactor message recipient calculation | Refactor | FEAT-004 | Subject Chapter IV |
| T-079 | Write unit tests for `ChannelMode` interface (pure virtual) | Red | FEAT-005 | `irc_channels.mmd` |
| T-080 | Implement `ChannelMode` abstract interface | Green | FEAT-005 | `irc_channels.mmd` |
| T-081 | Refactor `ChannelMode` interface | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-082 | Write unit tests for `InviteOnlyMode` strategy | Red | FEAT-005 | `irc_channels.mmd` |
| T-083 | Implement `InviteOnlyMode` (`i` flag) | Green | FEAT-005 | `irc_channels.mmd` |
| T-084 | Refactor `InviteOnlyMode` apply/check logic | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-085 | Write unit tests for `TopicRestrictedMode` strategy | Red | FEAT-005 | `irc_channels.mmd` |
| T-086 | Implement `TopicRestrictedMode` (`t` flag) | Green | FEAT-005 | `irc_channels.mmd` |
| T-087 | Refactor `TopicRestrictedMode` apply/check logic | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-088 | Write unit tests for `KeyMode` strategy | Red | FEAT-005 | `irc_channels.mmd` |
| T-089 | Implement `KeyMode` (`k` flag) | Green | FEAT-005 | `irc_channels.mmd` |
| T-090 | Refactor `KeyMode` apply/check logic | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-091 | Write unit tests for `OperatorMode` strategy | Red | FEAT-005 | `irc_channels.mmd` |
| T-092 | Implement `OperatorMode` (`o` flag) | Green | FEAT-005 | `irc_channels.mmd` |
| T-093 | Refactor `OperatorMode` apply/check logic | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-094 | Write unit tests for `LimitMode` strategy | Red | FEAT-005 | `irc_channels.mmd` |
| T-095 | Implement `LimitMode` (`l` flag) | Green | FEAT-005 | `irc_channels.mmd` |
| T-096 | Refactor `LimitMode` apply/check logic | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-097 | Write integration tests for `Channel` applying mode strategies | Red | FEAT-005 | `irc_channels.mmd` |
| T-098 | Integrate `ChannelMode` strategies into `Channel::modeStrategies` | Green | FEAT-005 | `irc_channels.mmd` |
| T-099 | Refactor `Channel` mode application loop | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-100 | Write unit tests for `KICK` command (operator only) | Red | FEAT-005 | Subject Chapter IV |
| T-101 | Implement `KICK` command | Green | FEAT-005 | Subject Chapter IV |
| T-102 | Refactor `KICK` operator permission checks | Refactor | FEAT-005 | Subject Chapter IV |
| T-103 | Write unit tests for `INVITE` command (operator only) | Red | FEAT-005 | Subject Chapter IV |
| T-104 | Implement `INVITE` command | Green | FEAT-005 | Subject Chapter IV |
| T-105 | Refactor `INVITE` invited-set logic | Refactor | FEAT-005 | Subject Chapter IV |
| T-106 | Write unit tests for `TOPIC` command | Red | FEAT-005 | Subject Chapter IV |
| T-107 | Implement `TOPIC` command | Green | FEAT-005 | Subject Chapter IV |
| T-108 | Refactor `TOPIC` setter/getter logic | Refactor | FEAT-005 | Subject Chapter IV |
| T-109 | Write unit tests for `MODE` command (all sub-flags) | Red | FEAT-005 | Subject Chapter IV |
| T-110 | Implement `MODE` command (`i`, `t`, `k`, `o`, `l`) | Green | FEAT-005 | Subject Chapter IV |
| T-111 | Refactor `MODE` flag parsing and application | Refactor | FEAT-005 | Subject Chapter IV |
| T-112 | Write unit tests for `PRIVMSG` command (delivery by nickname) | Red | FEAT-006 | Subject Chapter IV |
| T-113 | Implement `PRIVMSG` command | Green | FEAT-006 | Subject Chapter IV |
| T-114 | Refactor `PRIVMSG` target lookup | Refactor | FEAT-006 | Subject Chapter IV |
| T-115 | Write unit tests for `NOTICE` command | Red | FEAT-006 | Subject Chapter IV |
| T-116 | Implement `NOTICE` command | Green | FEAT-006 | Subject Chapter IV |
| T-117 | Refactor `NOTICE` delivery logic | Refactor | FEAT-006 | Subject Chapter IV |
| T-118 | Write integration tests for partial data aggregation (split across multiple `recv`) | Red | FEAT-007 | Subject Chapter IV |
| T-119 | Implement input buffer aggregation until complete line (`\n`) | Green | FEAT-007 | Subject Chapter IV |
| T-120 | Refactor buffer reassembly logic | Refactor | FEAT-007 | Subject Chapter IV |
| T-121 | Write integration tests for graceful client disconnection at any moment | Red | FEAT-007 | Subject Chapter IV |
| T-122 | Implement graceful disconnection (`close` fd, remove from `pollFds`, clean up channels/nicks) | Green | FEAT-007 | Subject Chapter IV |
| T-123 | Refactor disconnection cleanup | Refactor | FEAT-007 | Subject Chapter IV |
| T-124 | Write integration tests for clean shutdown on `SIGINT`/`SIGTERM` | Red | FEAT-007 | Subject Chapter IV |
| T-125 | Implement signal handling (`SIGINT`, `SIGTERM`, `SIGPIPE`) for clean shutdown | Green | FEAT-007 | Subject Chapter IV |
| T-126 | Refactor signal handler to stop event loop and close sockets | Refactor | FEAT-007 | Subject Chapter IV |
| T-127 | Write build verification script (compile all sources with `-Wall -Wextra -Werror -std=c++98`) | Red | FEAT-008 | Subject Chapter IV |
| T-128 | Create `Makefile` with `NAME = ircserv` and rules `all`, `clean`, `fclean`, `re`, `$(NAME)` | Green | FEAT-008 | Subject Chapter IV |
| T-129 | Refactor `Makefile` to avoid unnecessary relinking | Refactor | FEAT-008 | Subject Chapter IV |
| T-130 | Create entry point that parses `./ircserv <port> <password>` and validates arguments | Green | FEAT-008 | Subject Chapter IV |
| T-131 | Refactor argument validation and usage message | Refactor | FEAT-008 | Subject Chapter IV |
| T-132 | Organize directory structure (`include/`, `src/`, `tests/`, `docs/`) | Green | FEAT-008 | Subject Chapter IV |

---

## 3. Acceptance Criteria Table

| ID | Description | Associated Element |
|----|-------------|--------------------|
| AC-001 | Clients must authenticate with `PASS` before any other command is accepted | FEAT-001 |
| AC-002 | Clients can set a unique nickname via `NICK` | FEAT-001 |
| AC-003 | Clients can set username/realname via `USER` | FEAT-001 |
| AC-004 | A client is `registered` only after `PASS` + `NICK` + `USER` are complete | FEAT-001 |
| AC-005 | Nickname collisions are rejected | FEAT-001 |
| AC-006 | `Client` unit tests pass for all getters/setters | T-001 / T-002 / T-003 |
| AC-007 | `Client` buffer unit tests pass | T-004 / T-005 / T-006 |
| AC-008 | `ClientManager` unit tests pass for add/remove/find operations | T-007 / T-008 / T-009 |
| AC-009 | `NickManager` unit tests pass for reserve/release/isAvailable/isValid | T-010 / T-011 / T-012 |
| AC-010 | `IRCService` compiles with `ClientManager` and `NickManager` ownership | T-013 / T-014 / T-015 |
| AC-011 | Registration flow integration tests pass for `PASS`/`NICK`/`USER` sequences | T-016 / T-017 / T-018 |
| AC-012 | Server listens on the configured `port` and accepts TCP/IP connections | FEAT-002 |
| AC-013 | Multiple clients can connect simultaneously without blocking or forking | FEAT-002 |
| AC-014 | Single `poll()` (or equivalent) handles all read/write/listen operations | FEAT-002 |
| AC-015 | `IRCService` satisfies the `SocketService` interface contract | FEAT-002 |
| AC-016 | `TickResult` unit tests pass | T-019 / T-020 / T-021 |
| AC-017 | `SocketService` interface compiles as pure abstract class | T-022 / T-023 / T-024 |
| AC-018 | `SocketServer` `run()`/`stop()` lifecycle works without crashing | T-025 / T-026 / T-027 |
| AC-019 | `poll()` loop handles events without blocking indefinitely | T-028 / T-029 / T-030 |
| AC-020 | New client connections are accepted and registered | T-031 / T-032 / T-033 |
| AC-021 | `IRCService::tick` returns a populated `TickResult` | T-034 / T-035 / T-036 |
| AC-022 | Raw IRC lines (including partial data) are parsed into `IRCMessage` structures | FEAT-003 |
| AC-023 | Commands are dispatched through the handler chain to the correct command implementation | FEAT-003 |
| AC-024 | Unregistered clients are blocked from non-registration commands | FEAT-003 |
| AC-025 | `ReplyFormatter` produces correct IRC reply strings | FEAT-003 |
| AC-026 | `IRCMessage` unit tests pass | T-037 / T-038 / T-039 |
| AC-027 | `IRCParser` unit tests pass | T-040 / T-041 / T-042 |
| AC-028 | `CommandFactory` unit tests pass | T-043 / T-044 / T-045 |
| AC-029 | `Command` interface compiles as abstract | T-046 / T-047 / T-048 |
| AC-030 | `CommandHandler` chain unit tests pass | T-049 / T-050 / T-051 |
| AC-031 | Chain handler unit tests pass | T-052 / T-053 / T-054 |
| AC-032 | `CommandDispatcher` integration tests pass | T-055 / T-056 / T-057 |
| AC-033 | `CommandContext` unit tests pass | T-058 / T-059 / T-060 |
| AC-034 | `ReplyFormatter` unit tests pass | T-061 / T-062 / T-063 |
| AC-035 | Clients can join and leave channels | FEAT-004 |
| AC-036 | Channel operators and regular users exist | FEAT-004 |
| AC-037 | Messages sent to a channel are forwarded to every other client in that channel | FEAT-004 |
| AC-038 | Invalid channel names are rejected | FEAT-004 |
| AC-039 | `ChannelManager` unit tests pass | T-064 / T-065 / T-066 |
| AC-040 | `Channel` unit tests pass | T-067 / T-068 / T-069 |
| AC-041 | `JOIN` command integration tests pass | T-070 / T-071 / T-072 |
| AC-042 | `PART` command integration tests pass | T-073 / T-074 / T-075 |
| AC-043 | Channel message forwarding integration tests pass | T-076 / T-077 / T-078 |
| AC-044 | Channel modes can be applied and checked per strategy | FEAT-005 |
| AC-045 | Invite-only mode restricts joining to invited clients only | FEAT-005 |
| AC-046 | Key mode requires a correct key to join | FEAT-005 |
| AC-047 | Limit mode restricts maximum member count | FEAT-005 |
| AC-048 | Operator commands `KICK`, `INVITE`, `TOPIC`, `MODE` work correctly | FEAT-005 |
| AC-049 | `ChannelMode` interface unit tests pass | T-079 / T-080 / T-081 |
| AC-050 | `InviteOnlyMode` unit tests pass | T-082 / T-083 / T-084 |
| AC-051 | `TopicRestrictedMode` unit tests pass | T-085 / T-086 / T-087 |
| AC-052 | `KeyMode` unit tests pass | T-088 / T-089 / T-090 |
| AC-053 | `OperatorMode` unit tests pass | T-091 / T-092 / T-093 |
| AC-054 | `LimitMode` unit tests pass | T-094 / T-095 / T-096 |
| AC-055 | `Channel` mode integration tests pass | T-097 / T-098 / T-099 |
| AC-056 | `KICK` command unit tests pass | T-100 / T-101 / T-102 |
| AC-057 | `INVITE` command unit tests pass | T-103 / T-104 / T-105 |
| AC-058 | `TOPIC` command unit tests pass | T-106 / T-107 / T-108 |
| AC-059 | `MODE` command unit tests pass | T-109 / T-110 / T-111 |
| AC-060 | Clients can send private messages to other clients by nickname | FEAT-006 |
| AC-061 | `NOTICE` messages are delivered without requiring registration replies | FEAT-006 |
| AC-062 | `PRIVMSG` unit tests pass | T-112 / T-113 / T-114 |
| AC-063 | `NOTICE` unit tests pass | T-115 / T-116 / T-117 |
| AC-064 | Server does not crash when receiving partial data | FEAT-007 |
| AC-065 | Server does not crash on client disconnection at any moment | FEAT-007 |
| AC-066 | Server shuts down cleanly on signals without leaving fds open | FEAT-007 |
| AC-067 | Input buffer reassembles split commands correctly | T-118 / T-119 / T-120 |
| AC-068 | Client disconnection cleans up all associated state | T-121 / T-122 / T-123 |
| AC-069 | Signal handlers stop the event loop and close sockets | T-124 / T-125 / T-126 |
| AC-070 | `make all` / `make` builds the `ircserv` executable without errors | FEAT-008 |
| AC-071 | `make clean` removes object files; `make fclean` removes the binary; `make re` rebuilds from scratch | FEAT-008 |
| AC-072 | `./ircserv` with wrong arguments exits with a usage message | FEAT-008 |
| AC-073 | Compilation succeeds with `-std=c++98 -Wall -Wextra -Werror` and zero warnings | FEAT-008 |
| AC-074 | Build verification script passes | T-127 |
| AC-075 | `Makefile` contains all required targets | T-128 / T-129 |
| AC-076 | Entry point reads `port` and `password` from `argv` | T-130 / T-131 |
| AC-077 | Directory structure exists | T-132 |

---

## Constraints from the Subject (applied to all features)

- **Language**: C++ 98 only (`-std=c++98`, `-Wall -Wextra -Werror`)
- **Executable name**: `ircserv`
- **Arguments**: `./ircserv <port> <password>`
- **Makefile rules**: `NAME`, `all`, `clean`, `fclean`, `re` (no unnecessary relinking)
- **No forking**; all I/O non-blocking; single `poll()` (or equivalent: `select`, `kqueue`, `epoll`)
- **No errno-based decisions** after `read`/`recv`/`write`/`send`
- **No IRC client**, **no server-to-server communication**
- **TCP/IP** (v4 or v6)
- **Allowed external functions**: `socket`, `close`, `setsockopt`, `getsockname`, `getprotobyname`, `gethostbyname`, `getaddrinfo`, `freeaddrinfo`, `bind`, `connect`, `listen`, `accept`, `htons`, `htonl`, `ntohs`, `ntohl`, `inet_addr`, `inet_ntoa`, `inet_ntop`, `send`, `recv`, `signal`, `sigaction`, `sigemptyset`, `sigfillset`, `sigaddset`, `sigdelset`, `sigismember`, `lseek`, `fstat`, `fcntl`, `poll`
- **Bonus** (only if mandatory is perfect): file transfer, bot
- **Build system**: The existing CMake/Makefile infrastructure will be used for development. The subject-compliant Makefile (`NAME`, `all`, `clean`, `fclean`, `re`) will be implemented as FEAT-008 *after* the core server is functional, and then adjusted to match the 42 guidelines.

---

## TDD Methodology (applied to all tasks)

Every task follows the **Test-Driven Development** cycle:

1. **Red** — Write a failing test (unit or integration) that specifies the expected behavior.
2. **Green** — Implement the minimum production code required to make the test pass.
3. **Refactor** — Clean up the code while keeping tests passing; ensure `-Wall -Wextra -Werror -std=c++98` compliance.

Tasks are ordered so that tests for a feature are written before or alongside the production code they validate.

---

## 4. Detailed Breakdown by Feature

### FEAT-001 — Core IRC Service & Client Management

Derived from `irc_clients.mmd` (IRCService orchestrator, Client entity, ClientManager/NickManager registries).

**Tasks:** T-001 to T-018  
**Acceptance Criteria:** AC-001 to AC-011  
**Depends on:** None

### FEAT-002 — Network Layer & Socket I/O

Derived from `irc_network_layer_pull.mmd` (`SocketService` interface, `TickResult` struct, `SocketServer` network class). Implements the subject's networking requirements: `poll()`, non-blocking I/O, no forking, TCP/IP.

**Tasks:** T-019 to T-036  
**Acceptance Criteria:** AC-012 to AC-021  
**Depends on:** FEAT-001

### FEAT-003 — Command Parsing & Dispatching

Derived from `irc_commands.mmd` (`IRCParser`, `IRCMessage`, `CommandDispatcher`, `CommandHandler` chain, `CommandFactory`, `Command` interface, `XxxCommand`, `CommandContext`, `ReplyFormatter`).

**Tasks:** T-037 to T-063  
**Acceptance Criteria:** AC-022 to AC-034  
**Depends on:** FEAT-001, FEAT-002

### FEAT-004 — Channel Management

Derived from `irc_channels.mmd` (`ChannelManager` registry, `Channel` entity). Implements subject requirements: `JOIN`, `PART`, operators and regular users, channel message forwarding.

**Tasks:** T-064 to T-078  
**Acceptance Criteria:** AC-035 to AC-043  
**Depends on:** FEAT-001, FEAT-003

### FEAT-005 — Channel Modes & Operator Commands

Derived from `irc_channels.mmd` (`ChannelMode` interface and strategies: `InviteOnlyMode`, `TopicRestrictedMode`, `KeyMode`, `OperatorMode`, `LimitMode`). Implements subject `MODE` sub-flags (`i`, `t`, `k`, `o`, `l`) and operator commands `KICK`, `INVITE`, `TOPIC`.

**Tasks:** T-079 to T-111  
**Acceptance Criteria:** AC-044 to AC-059  
**Depends on:** FEAT-004

### FEAT-006 — Private Messages & Notice

Implements subject requirement: send and receive private messages using `PRIVMSG` / `NOTICE` between clients.

**Tasks:** T-112 to T-117  
**Acceptance Criteria:** AC-060 to AC-063  
**Depends on:** FEAT-003, FEAT-004

### FEAT-007 — Robustness & Edge Cases

Implements subject robustness requirements: no crashes, partial data handling, non-blocking I/O without `errno` reliance, clean shutdown.

**Tasks:** T-118 to T-126  
**Acceptance Criteria:** AC-064 to AC-069  
**Depends on:** FEAT-002

### FEAT-008 — Build System & Project Skeleton *(deferred)*

Establishes the compilable foundation required by the subject: Makefile rules, C++98 standard, warning flags, executable name, and command-line arguments.

> **Note:** This feature is intentionally last. During development, the existing CMake/Makefile infrastructure in the repository will be used. Once the core server is complete, this feature will be implemented to satisfy the subject's Makefile requirements (`NAME`, `all`, `clean`, `fclean`, `re`) and adjusted to match the 42 guidelines.

**Tasks:** T-127 to T-132  
**Acceptance Criteria:** AC-070 to AC-077  
**Depends on:** All above

---

## Dependency Summary

| Feature | Depends On |
|---------|------------|
| FEAT-001 | None (core service & clients) |
| FEAT-002 | FEAT-001 (`IRCService` implements `SocketService`) |
| FEAT-003 | FEAT-001, FEAT-002 (uses managers + event loop) |
| FEAT-004 | FEAT-001, FEAT-003 (uses `Client`, `NickManager`, command dispatching) |
| FEAT-005 | FEAT-004 (uses `Channel`) |
| FEAT-006 | FEAT-003, FEAT-004 (uses command dispatching + clients) |
| FEAT-007 | FEAT-002 (uses socket/event loop) |
| FEAT-008 | All above (builds the complete project) |
