# simple_cache

A simple process-based cache application built with Erlang/OTP and Rebar3.

Each cached value is stored in a separate `gen_server` process. A Mnesia table maps cache keys to cache element processes.

## Features

- Process-based cache elements using `gen_server`
- Mnesia-based key-to-process registry
- Configurable lease time
- Insert, lookup, update, and delete operations
- OTP supervision tree
- Configurable Erlang Logger
- Rebar3 build and test workflow

## Architecture

```text
                         simple_cache
                              |
                 +------------+------------+
                 |                         |
                 v                         v
          simple_cache_sup       simple_cache_store
                 |                         |
        +--------+--------+               v
        |        |        |            Mnesia
        v        v        v       key -> process PID
     element  element  element
      (key_1)  (key_2)  (key_3)
        |        |        |
        +--------+--------+
                 |
             gen_server
             cache value

                    simple_cache_logger
                              |
                              v
                           Logger
```

The `simple_cache` module provides the public API and coordinates the cache store and cache element processes.

## Configuration

Application configuration is stored in `config/sys.config`. At least one
reachable node must be listed in `contract_nodes`; an empty list causes
application startup to fail with `no_contact_nodes_configured`.

Example:

```erlang
[
    {simple_cache,
        [
            {contract_nodes, ['cache1@host1', 'cache2@host2']},
            {cluster_connection_wait_time, 6000},
            {logger,
                #{
                    enabled => true,
                    primary_level => info,
                    format => modern
                }}
        ]}
].
```

Replace the example node names with reachable, distributed Erlang nodes.
`cluster_connection_wait_time` is the maximum time in milliseconds to wait for
cluster membership to become visible after a configured node responds. Startup
continues if this wait expires before membership becomes visible.

Entries created with `simple_cache:insert/2` expire after 86400 seconds. Use
`simple_cache:insert/3` to specify a different lease time in seconds; the
default lease time is not an application configuration option.

The Mnesia table stores the key-to-process mapping; cached values live in
worker processes and are lost if those processes terminate.

## Build

Compile the application with:

```bash
rebar3 compile
```

## Test

Run the test suite with:

```bash
rebar3 eunit
```

Rebar3 fetches the `resource_discovery` Git dependency declared in
`rebar.config`.

## Format

Format the Erlang source code with:

```bash
rebar3 format
```

This command uses the project's configured `rebar3_format` plugin, which is
deprecated.

## Shell

Start an Erlang shell with the application configuration loaded:

```bash
rebar3 shell
```

The cache can then be used through its public API:

```erlang
simple_cache:insert(my_key, "some_value").

simple_cache:lookup(my_key).

simple_cache:insert(my_key, "new_value", 3600).

simple_cache:delete(my_key).
```

## License

See [LICENSE.md](LICENSE.md).