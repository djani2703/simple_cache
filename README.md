# simple_cache

A simple process-based cache application built with Erlang/OTP and Rebar3.

Each cached value is stored in a separate `gen_server` process. An ETS table is used as a registry that maps cache keys to cache element processes.

## Features

- Process-based cache elements using `gen_server`
- ETS-based key-to-process registry
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
        |        |        |              ETS
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

Application configuration is stored in `config/sys.config`.

Example:

```erlang
[
    {simple_cache,
        [
            {default_lease_time, 86400},
            {contract_nodes, []},
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

`default_lease_time` specifies the default lifetime of a cache entry in seconds.
`contract_nodes` lists the Erlang nodes to connect to; an empty list runs the
cache standalone. `cluster_connection_wait_time` sets how long startup waits
for the configured cluster nodes, in milliseconds.

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

The test suite starts `resource_discovery` before `simple_cache`; the
`resource_discovery` project must be checked out alongside this repository.

## Format

Format the Erlang source code with:

```bash
rebar3 format
```

## Shell

Start an Erlang shell with the application configuration loaded:

```bash
rebar3 shell
```

The cache can then be used through its public API:

```erlang
simple_cache:insert(my_key, "some_value").

simple_cache:lookup(my_key).

simple_cache:insert(my_key, "new_value").

simple_cache:delete(my_key).
```

## License

This project is for learning and experimentation with Erlang/OTP.