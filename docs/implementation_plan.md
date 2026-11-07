# Implementation Plan

Traceability plan for the **ft_irc** IRC server project, derived from:

- `en.subject.pdf` (project requirements, Chapter IV — Mandatory Part)
- `docs/diagrams/class/irc_clients.mmd`
- `docs/diagrams/class/irc_network_layer_pull.mmd`
- `docs/diagrams/class/irc_commands.mmd`
- `docs/diagrams/class/irc_channels.mmd`
- `docs/diagrams/class/irc_registration.mmd`
- `docs/diagrams/class/irc_robustness.mmd`

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
| FEAT-001 | Core IRC Service & Client Management | IRCService orchestrator, Client entity, ClientManager, NickManager registries | `irc_clients.mmd` |
| FEAT-002 | Network Layer & Socket I/O | SocketService interface, TickResult, SocketServer, poll() event loop, non-blocking I/O | `irc_network_layer_pull.mmd` |
| FEAT-003 | Command Infrastructure | IRCParser, IRCMessage, CommandDispatcher, CommandHandler chain, CommandFactory, CommandContext, ReplyFormatter | `irc_commands.mmd` |
| FEAT-004 | Registration & Authentication | PASS, NICK, USER commands, RegistrationCheckHandler, authenticated/registered state on Client | `irc_registration.mmd` |
| FEAT-005 | Channel Management | ChannelManager registry, Channel entity, JOIN/PART, channel message broadcasting | `irc_channels.mmd` |
| FEAT-006 | Channel Modes & Operator Commands | ChannelMode strategies (i, t, k, o, l), KICK, INVITE, TOPIC, MODE commands | `irc_channels.mmd` |
| FEAT-007 | Private Messages & System Commands | PRIVMSG, NOTICE, QUIT, PING, CAP commands | `irc_commands.mmd` |
| FEAT-008 | Robustness & Edge Cases | Input buffer aggregation, graceful disconnection, signal handling, no crashes | `irc_robustness.mmd` |
| FEAT-009 | Build System & Project Skeleton | Makefile rules, C++98 flags, executable name `ircserv`, argument parsing | Subject Chapter IV |

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
| T-016 | Write unit tests for `TickResult` struct fields and default values | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-017 | Implement `TickResult` struct | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-018 | Refactor `TickResult` for copy semantics | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-019 | Write unit tests for `SocketService` interface contract (pure virtual methods) | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-020 | Implement `SocketService` pure abstract interface | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-021 | Refactor `SocketService` interface | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-022 | Write integration tests for `SocketServer` listen/accept lifecycle | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-023 | Implement `SocketServer` class (port, listenFd, running, pollFds, pendingOutput, closingFds) | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-024 | Refactor `SocketServer` socket setup (`socket`, `bind`, `listen`, `setsockopt`, `fcntl` non-blocking) | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-025 | Write integration tests for single `poll()` event loop handling listen/read/write | Red | FEAT-002 | Subject Chapter IV |
| T-026 | Implement event loop with single `poll()` call | Green | FEAT-002 | Subject Chapter IV |
| T-027 | Refactor event loop to avoid blocking and `errno` checks | Refactor | FEAT-002 | Subject Chapter IV |
| T-028 | Write integration tests for client connect/disconnect via `accept`/`close` | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-029 | Implement `accept` for new connections and fd registration in `pollFds` | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-030 | Refactor connection/disconnection cleanup | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-031 | Write unit tests for `IRCService` implementing `SocketService::tick` | Red | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-032 | Wire `IRCService` to implement `SocketService` interface | Green | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-033 | Refactor `IRCService::tick` to return populated `TickResult` | Refactor | FEAT-002 | `irc_network_layer_pull.mmd` |
| T-034 | Write unit tests for `IRCMessage` parsing fields | Red | FEAT-003 | `irc_commands.mmd` |
| T-035 | Implement `IRCMessage` data class | Green | FEAT-003 | `irc_commands.mmd` |
| T-036 | Refactor `IRCMessage` field accessors | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-037 | Write unit tests for `IRCParser` (valid and malformed lines) | Red | FEAT-003 | `irc_commands.mmd` |
| T-038 | Implement `IRCParser` utility (`parseLine`, `extractPrefix`, `extractCommand`, `extractParams`) | Green | FEAT-003 | `irc_commands.mmd` |
| T-039 | Refactor `IRCParser` for partial-line handling | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-040 | Write unit tests for `CommandFactory` (register/create by name) | Red | FEAT-003 | `irc_commands.mmd` |
| T-041 | Implement `CommandFactory` | Green | FEAT-003 | `irc_commands.mmd` |
| T-042 | Refactor `CommandFactory` registration map | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-043 | Write unit tests for `Command` interface (pure virtual methods) | Red | FEAT-003 | `irc_commands.mmd` |
| T-044 | Implement `Command` abstract interface | Green | FEAT-003 | `irc_commands.mmd` |
| T-045 | Refactor `Command` interface | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-046 | Write unit tests for `CommandHandler` chain propagation | Red | FEAT-003 | `irc_commands.mmd` |
| T-047 | Implement `CommandHandler` chain interface | Green | FEAT-003 | `irc_commands.mmd` |
| T-048 | Refactor `CommandHandler` chain links | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-049 | Write unit tests for chain handlers (`RegistrationCheckHandler`, `ParamCheckHandler`, `ExecutionHandler`) | Red | FEAT-003 | `irc_commands.mmd` |
| T-050 | Implement chain handlers | Green | FEAT-003 | `irc_commands.mmd` |
| T-051 | Refactor handler logic for registration/param/execution separation | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-052 | Write integration tests for `CommandDispatcher` dispatch flow | Red | FEAT-003 | `irc_commands.mmd` |
| T-053 | Implement `CommandDispatcher` (chain ownership, `dispatchNext`, context creation) | Green | FEAT-003 | `irc_commands.mmd` |
| T-054 | Refactor `CommandDispatcher` parser/factory integration | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-055 | Write unit tests for `CommandContext` (`send`/`disconnect` helpers) | Red | FEAT-003 | `irc_commands.mmd` |
| T-056 | Implement `CommandContext` | Green | FEAT-003 | `irc_commands.mmd` |
| T-057 | Refactor `CommandContext` output appending | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-058 | Write unit tests for `ReplyFormatter` reply strings | Red | FEAT-003 | `irc_commands.mmd` |
| T-059 | Implement `ReplyFormatter` | Green | FEAT-003 | `irc_commands.mmd` |
| T-060 | Refactor `ReplyFormatter` formatting logic | Refactor | FEAT-003 | `irc_commands.mmd` |
| T-061 | Write unit tests for `PASS` command | Red | FEAT-004 | `irc_registration.mmd` |
| T-062 | Implement `PASS` command | Green | FEAT-004 | `irc_registration.mmd` |
| T-063 | Refactor `PASS` authentication check | Refactor | FEAT-004 | `irc_registration.mmd` |
| T-064 | Write unit tests for `NICK` command | Red | FEAT-004 | `irc_registration.mmd` |
| T-065 | Implement `NICK` command | Green | FEAT-004 | `irc_registration.mmd` |
| T-066 | Refactor `NICK` nickname collision check | Refactor | FEAT-004 | `irc_registration.mmd` |
| T-067 | Write unit tests for `USER` command | Red | FEAT-004 | `irc_registration.mmd` |
| T-068 | Implement `USER` command | Green | FEAT-004 | `irc_registration.mmd` |
| T-069 | Refactor `USER` username/realname parsing | Refactor | FEAT-004 | `irc_registration.mmd` |
| T-070 | Write unit tests for `RegistrationCheckHandler` | Red | FEAT-004 | `irc_registration.mmd` |
| T-071 | Implement `RegistrationCheckHandler` in command chain | Green | FEAT-004 | `irc_registration.mmd` |
| T-072 | Refactor registration flow state machine | Refactor | FEAT-004 | `irc_registration.mmd` |
| T-073 | Write unit tests for `ChannelManager` (create/find/destroy/list) | Red | FEAT-005 | `irc_channels.mmd` |
| T-074 | Implement `ChannelManager` registry (map name → Channel*) | Green | FEAT-005 | `irc_channels.mmd` |
| T-075 | Refactor `ChannelManager` channel lifecycle | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-076 | Write unit tests for `Channel` member/operator management | Red | FEAT-005 | `irc_channels.mmd` |
| T-077 | Implement `Channel` class (name, topic, creator, members/operators/invited sets) | Green | FEAT-005 | `irc_channels.mmd` |
| T-078 | Refactor `Channel` membership logic | Refactor | FEAT-005 | `irc_channels.mmd` |
| T-079 | Write integration tests for `JOIN` command | Red | FEAT-005 | Subject Chapter IV |
| T-080 | Implement `JOIN` command (create channel if needed, forward join) | Green | FEAT-005 | Subject Chapter IV |
| T-081 | Refactor `JOIN` notification broadcasting | Refactor | FEAT-005 | Subject Chapter IV |
| T-082 | Write integration tests for `PART` command | Red | FEAT-005 | Subject Chapter IV |
| T-083 | Implement `PART` command (leave channel, destroy if empty) | Green | FEAT-005 | Subject Chapter IV |
| T-084 | Refactor `PART` cleanup logic | Refactor | FEAT-005 | Subject Chapter IV |
| T-085 | Write integration tests for channel message broadcasting | Red | FEAT-005 | Subject Chapter IV |
| T-086 | Implement channel message forwarding to all members | Green | FEAT-005 | Subject Chapter IV |
| T-087 | Refactor message recipient calculation | Refactor | FEAT-005 | Subject Chapter IV |
| T-088 | Write unit tests for `ChannelMode` interface (pure virtual) | Red | FEAT-006 | `irc_channels.mmd` |
| T-089 | Implement `ChannelMode` abstract interface | Green | FEAT-006 | `irc_channels.mmd` |
| T-090 | Refactor `ChannelMode` interface | Refactor | FEAT-006 | `irc_channels.mmd` |
| T-091 | Write unit tests for `InviteOnlyMode` strategy | Red | FEAT-006 | `irc_channels.mmd` |
| T-092 | Implement `InviteOnlyMode` (`i` flag) | Green | FEAT-006 | `irc_channels.mmd` |
| T-093 | Refactor `InviteOnlyMode` apply/check logic | Refactor | FEAT-006 | `irc_channels.mmd` |
| T-094 | Write unit tests for `TopicRestrictedMode` strategy | Red | FEAT-006 | `irc_channels.mmd` |
| T-095 | Implement `TopicRestrictedMode` (`t` flag) | Green | FEAT-006 | `irc_channels.mmd` |
| T-096 | Refactor `TopicRestrictedMode` apply/check logic | Refactor | FEAT-006 | `irc_channels.mmd` |
| T-097 | Write unit tests for `KeyMode` strategy | Red | FEAT-006 | `irc_channels.mmd` |
| T-098 | Implement `KeyMode` (`k` flag) | Green | FEAT-006 | `irc_channels.mmd` |
| T-099 | Refactor `KeyMode` apply/check logic | Refactor | FEAT-006 | `irc_channels.mmd` |
| T-100 | Write unit tests for `OperatorMode` strategy | Red | FEAT-006 | `irc_channels.mmd` |
| T-101 | Implement `OperatorMode` (`o` flag) | Green | FEAT-006 | `irc_channels.mmd` |
| T-102 | Refactor `OperatorMode` apply/check logic | Refactor | FEAT-006 | `irc_channels.mmd` |
| T-103 | Write unit tests for `LimitMode` strategy | Red | FEAT-006 | `irc_channels.mmd` |
| T-104 | Implement `LimitMode` (`l` flag) | Green | FEAT-006 | `irc_channels.mmd` |
| T-105 | Refactor `LimitMode` apply/check logic | Refactor | FEAT-006 | `irc_channels.mmd` |
| T-106 | Write integration tests for `Channel` applying mode strategies | Red | FEAT-006 | `irc_channels.mmd` |
| T-107 | Integrate `ChannelMode` strategies into `Channel::modeStrategies` | Green | FEAT-006 | `irc_channels.mmd` |
| T-108 | Refactor `Channel` mode application loop | Refactor | FEAT-006 | `irc_channels.mmd` |
| T-109 | Write unit tests for `KICK` command (operator only) | Red | FEAT-006 | Subject Chapter IV |
| T-110 | Implement `KICK` command | Green | FEAT-006 | Subject Chapter IV |
| T-111 | Refactor `KICK` operator permission checks | Refactor | FEAT-006 | Subject Chapter IV |
| T-112 | Write unit tests for `INVITE` command (operator only) | Red | FEAT-006 | Subject Chapter IV |
| T-113 | Implement `INVITE` command | Green | FEAT-006 | Subject Chapter IV |
| T-114 | Refactor `INVITE` invited-set logic | Refactor | FEAT-006 | Subject Chapter IV |
| T-115 | Write unit tests for `TOPIC` command | Red | FEAT-006 | Subject Chapter IV |
| T-116 | Implement `TOPIC` command | Green | FEAT-006 | Subject Chapter IV |
| T-117 | Refactor `TOPIC` setter/getter logic | Refactor | FEAT-006 | Subject Chapter IV |
| T-118 | Write unit tests for `MODE` command (all sub-flags) | Red | FEAT-006 | Subject Chapter IV |
| T-119 | Implement `MODE` command (`i`, `t`, `k`, `o`, `l`) | Green | FEAT-006 | Subject Chapter IV |
| T-120 | Refactor `MODE` flag parsing and application | Refactor | FEAT-006 | Subject Chapter IV |
| T-121 | Write unit tests for `PRIVMSG` command (delivery by nickname) | Red | FEAT-007 | Subject Chapter IV |
| T-122 | Implement `PRIVMSG` command | Green | FEAT-007 | Subject Chapter IV |
| T-123 | Refactor `PRIVMSG` target lookup | Refactor | FEAT-007 | Subject Chapter IV |
| T-124 | Write unit tests for `NOTICE` command | Red | FEAT-007 | Subject Chapter IV |
| T-125 | Implement `NOTICE` command | Green | FEAT-007 | Subject Chapter IV |
| T-126 | Refactor `NOTICE` delivery logic | Refactor | FEAT-007 | Subject Chapter IV |
| T-127 | Write unit tests for `QUIT` command | Red | FEAT-007 | Subject Chapter IV |
| T-128 | Implement `QUIT` command | Green | FEAT-007 | Subject Chapter IV |
| T-129 | Refactor `QUIT` cleanup logic | Refactor | FEAT-007 | Subject Chapter IV |
| T-130 | Write unit tests for `PING`/`PONG` handling | Red | FEAT-007 | Subject Chapter IV |
| T-131 | Implement `PING`/`PONG` handling | Green | FEAT-007 | Subject Chapter IV |
| T-132 | Refactor `PING`/`PONG` timeout logic | Refactor | FEAT-007 | Subject Chapter IV |
| T-133 | Write unit tests for `CAP` command | Red | FEAT-007 | Subject Chapter IV |
| T-134 | Implement `CAP` command | Green | FEAT-007 | Subject Chapter IV |
| T-135 | Refactor `CAP` negotiation logic | Refactor | FEAT-007 | Subject Chapter IV |
| T-136 | Write integration tests for partial data aggregation (split across multiple `recv`) | Red | FEAT-008 | Subject Chapter IV |
| T-137 | Implement input buffer aggregation until complete line (`\n`) | Green | FEAT-008 | Subject Chapter IV |
| T-138 | Refactor buffer reassembly logic | Refactor | FEAT-008 | Subject Chapter IV |
| T-139 | Write integration tests for graceful client disconnection at any moment | Red | FEAT-008 | `irc_robustness.mmd` |
| T-140 | Implement graceful disconnection (`close` fd, remove from `pollFds`, clean up channels/nicks) | Green | FEAT-008 | `irc_robustness.mmd` |
| T-141 | Refactor disconnection cleanup | Refactor | FEAT-008 | `irc_robustness.mmd` |
| T-142 | Write integration tests for clean shutdown on `SIGINT`/`SIGTERM` | Red | FEAT-008 | `irc_robustness.mmd` |
| T-143 | Implement signal handling (`SIGINT`, `SIGTERM`, `SIGPIPE`) for clean shutdown | Green | FEAT-008 | `irc_robustness.mmd` |
| T-144 | Refactor signal handler to stop event loop and close sockets | Refactor | FEAT-008 | `irc_robustness.mmd` |
| T-145 | Write build verification script (compile all sources with `-Wall -Wextra -Werror -std=c++98`) | Red | FEAT-009 | Subject Chapter IV |
| T-146 | Create `Makefile` with `NAME = ircserv` and rules `all`, `clean`, `fclean`, `re`, `$(NAME)` | Green | FEAT-009 | Subject Chapter IV |
| T-147 | Refactor `Makefile` to avoid unnecessary relinking | Refactor | FEAT-009 | Subject Chapter IV |
| T-148 | Create entry point that parses `./ircserv <port> <password>` and validates arguments | Green | FEAT-009 | Subject Chapter IV |
| T-149 | Refactor argument validation and usage message | Refactor | FEAT-009 | Subject Chapter IV |
| T-150 | Organize directory structure (`include/`, `src/`, `tests/`, `docs/`) | Green | FEAT-009 | Subject Chapter IV |

---

## 3. Acceptance Criteria Table

| ID | Description | Associated Element |
|----|-------------|--------------------|
| AC-001 | `Client` unit tests pass for all getters/setters | FEAT-001 |
| AC-002 | `Client` buffer unit tests pass | FEAT-001 |
| AC-003 | `ClientManager` unit tests pass for add/remove/find operations | FEAT-001 |
| AC-004 | `NickManager` unit tests pass for reserve/release/isAvailable/isValid | FEAT-001 |
| AC-005 | `IRCService` compiles with `ClientManager` and `NickManager` ownership | FEAT-001 |
| AC-006 | Nickname collisions are rejected | FEAT-001 |
| AC-007 | `TickResult` unit tests pass | FEAT-002 |
| AC-008 | `SocketService` interface compiles as pure abstract class | FEAT-002 |
| AC-009 | `SocketServer` `run()`/`stop()` lifecycle works without crashing | FEAT-002 |
| AC-010 | `poll()` loop handles events without blocking indefinitely | FEAT-002 |
| AC-011 | `IRCService` satisfies the `SocketService` interface contract | FEAT-002 |
| AC-012 | New client connections are accepted and registered | FEAT-002 |
| AC-013 | `IRCService::tick` returns a populated `TickResult` | FEAT-002 |
| AC-014 | `IRCMessage` unit tests pass | FEAT-003 |
| AC-015 | `IRCParser` unit tests pass | FEAT-003 |
| AC-016 | `CommandFactory` unit tests pass | FEAT-003 |
| AC-017 | `Command` interface compiles as abstract | FEAT-003 |
| AC-018 | `CommandHandler` chain unit tests pass | FEAT-003 |
| AC-019 | Chain handler unit tests pass | FEAT-003 |
| AC-020 | `CommandDispatcher` integration tests pass | FEAT-003 |
| AC-021 | `CommandContext` unit tests pass | FEAT-003 |
| AC-022 | `ReplyFormatter` unit tests pass | FEAT-003 |
| AC-023 | Clients must authenticate with `PASS` before any other command is accepted | FEAT-004 |
| AC-024 | Clients can set a unique nickname via `NICK` | FEAT-004 |
| AC-025 | Clients can set username/realname via `USER` | FEAT-004 |
| AC-026 | A client is `registered` only after `PASS` + `NICK` + `USER` are complete | FEAT-004 |
| AC-027 | Unregistered clients are blocked from non-registration commands | FEAT-004 |
| AC-028 | Registration flow integration tests pass for `PASS`/`NICK`/`USER` sequences | FEAT-004 |
| AC-029 | Clients can join and leave channels | FEAT-005 |
| AC-030 | Channel operators and regular users exist | FEAT-005 |
| AC-031 | Messages sent to a channel are forwarded to every other client in that channel | FEAT-005 |
| AC-032 | Invalid channel names are rejected | FEAT-005 |
| AC-033 | `ChannelManager` unit tests pass | FEAT-005 |
| AC-034 | `Channel` unit tests pass | FEAT-005 |
| AC-035 | `JOIN` command integration tests pass | FEAT-005 |
| AC-036 | `PART` command integration tests pass | FEAT-005 |
| AC-037 | Channel message forwarding integration tests pass | FEAT-005 |
| AC-038 | Channel modes can be applied and checked per strategy | FEAT-006 |
| AC-039 | Invite-only mode restricts joining to invited clients only | FEAT-006 |
| AC-040 | Key mode requires a correct key to join | FEAT-006 |
| AC-041 | Limit mode restricts maximum member count | FEAT-006 |
| AC-042 | Operator commands `KICK`, `INVITE`, `TOPIC`, `MODE` work correctly | FEAT-006 |
| AC-043 | Clients can send private messages to other clients by nickname | FEAT-007 |
| AC-044 | `NOTICE` messages are delivered without requiring registration replies | FEAT-007 |
| AC-045 | `QUIT` command cleanly disconnects a client | FEAT-007 |
| AC-046 | `PING`/`PONG` handling keeps connections alive | FEAT-007 |
| AC-047 | `CAP` command negotiation works correctly | FEAT-007 |
| AC-048 | Server does not crash when receiving partial data | FEAT-008 |
| AC-049 | Server does not crash on client disconnection at any moment | FEAT-008 |
| AC-050 | Server shuts down cleanly on signals without leaving fds open | FEAT-008 |
| AC-051 | Input buffer reassembles split commands correctly | FEAT-008 |
| AC-052 | Client disconnection cleans up all associated state | FEAT-008 |
| AC-053 | Signal handlers stop the event loop and close sockets | FEAT-008 |
| AC-054 | `make all` / `make` builds the `ircserv` executable without errors | FEAT-009 |
| AC-055 | `make clean` removes object files; `make fclean` removes the binary; `make re` rebuilds from scratch | FEAT-009 |
| AC-056 | `./ircserv` with wrong arguments exits with a usage message | FEAT-009 |
| AC-057 | Compilation succeeds with `-std=c++98 -Wall -Wextra -Werror` and zero warnings | FEAT-009 |
| AC-058 | Build verification script passes | FEAT-009 |
| AC-059 | `Makefile` contains all required targets | FEAT-009 |
| AC-060 | Entry point reads `port` and `password` from `argv` | FEAT-009 |
| AC-061 | Directory structure exists | FEAT-009 |

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
- **Build system**: The existing CMake/Makefile infrastructure will be used for development. The subject-compliant Makefile (`NAME`, `all`, `clean`, `fclean`, `re`) will be implemented as FEAT-009 after the core server is functional, and then adjusted to match the 42 guidelines.

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

**Tasks:** T-001 to T-015  
**Acceptance Criteria:** AC-001 to AC-006  
**Depends on:** None

### FEAT-002 — Network Layer & Socket I/O

Derived from `irc_network_layer_pull.mmd` (`SocketService` interface, `TickResult` struct, `SocketServer` network class). Implements the subject's networking requirements: `poll()`, non-blocking I/O, no forking, TCP/IP.

**Tasks:** T-016 to T-033  
**Acceptance Criteria:** AC-007 to AC-013  
**Depends on:** FEAT-001

### FEAT-003 — Command Infrastructure

Derived from `irc_commands.mmd` (`IRCParser`, `IRCMessage`, `CommandDispatcher`, `CommandHandler` chain, `CommandFactory`, `Command` interface, `CommandContext`, `ReplyFormatter`).

**Tasks:** T-034 to T-060  
**Acceptance Criteria:** AC-014 to AC-022  
**Depends on:** FEAT-001, FEAT-002

### FEAT-004 — Registration & Authentication

Derived from `irc_registration.mmd`. Implements registration commands `PASS`, `NICK`, `USER`, the `RegistrationCheckHandler` in the command chain, and the `authenticated`/`registered` state on `Client`.

**Tasks:** T-061 to T-072  
**Acceptance Criteria:** AC-023 to AC-028  
**Depends on:** FEAT-001, FEAT-003

### FEAT-005 — Channel Management

Derived from `irc_channels.mmd` (`ChannelManager` registry, `Channel` entity). Implements subject requirements: `JOIN`, `PART`, operators and regular users, channel message forwarding.

**Tasks:** T-073 to T-087  
**Acceptance Criteria:** AC-029 to AC-037  
**Depends on:** FEAT-001, FEAT-003, FEAT-004

### FEAT-006 — Channel Modes & Operator Commands

Derived from `irc_channels.mmd` (`ChannelMode` interface and strategies: `InviteOnlyMode`, `TopicRestrictedMode`, `KeyMode`, `OperatorMode`, `LimitMode`). Implements subject `MODE` sub-flags (`i`, `t`, `k`, `o`, `l`) and operator commands `KICK`, `INVITE`, `TOPIC`, `MODE`.

**Tasks:** T-088 to T-120  
**Acceptance Criteria:** AC-038 to AC-042  
**Depends on:** FEAT-005

### FEAT-007 — Private Messages & System Commands

Implements subject requirement: send and receive private messages using `PRIVMSG` / `NOTICE` between clients. Also implements system commands `QUIT`, `PING`/`PONG`, and `CAP`.

**Tasks:** T-121 to T-135  
**Acceptance Criteria:** AC-043 to AC-047  
**Depends on:** FEAT-003, FEAT-005

### FEAT-008 — Robustness & Edge Cases

Implements subject robustness requirements: no crashes, partial data handling, non-blocking I/O without `errno` reliance, clean shutdown, graceful disconnection.

**Tasks:** T-136 to T-144  
**Acceptance Criteria:** AC-048 to AC-053  
**Depends on:** FEAT-001, FEAT-002, FEAT-005, FEAT-007

### FEAT-009 — Build System & Project Skeleton

Establishes the compilable foundation required by the subject: Makefile rules, C++98 standard, warning flags, executable name, and command-line arguments.

**Tasks:** T-145 to T-150  
**Acceptance Criteria:** AC-054 to AC-061  
**Depends on:** All above

---

## Dependency Summary

| Feature | Depends On |
|---------|------------|
| FEAT-001 | None (core service & clients) |
| FEAT-002 | FEAT-001 (`IRCService` implements `SocketService`) |
| FEAT-003 | FEAT-001, FEAT-002 (uses managers + event loop) |
| FEAT-004 | FEAT-001, FEAT-003 (uses `Client`, command chain) |
| FEAT-005 | FEAT-001, FEAT-003, FEAT-004 (uses `Client`, `NickManager`, command dispatching) |
| FEAT-006 | FEAT-005 (uses `Channel`) |
| FEAT-007 | FEAT-003, FEAT-005 (uses command dispatching + channels) |
| FEAT-008 | FEAT-001, FEAT-002, FEAT-005, FEAT-007 (uses clients, sockets, channels, system commands) |
| FEAT-009 | All above (builds the complete project) |
