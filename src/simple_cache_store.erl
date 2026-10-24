%%%-------------------------------------------------------------------
%% @doc
%% Simple Cache Store (Mnesia registry).
%%
%% Maintains a mapping between cache keys and cache element process PIDs.
%%
%% The mapping is stored in a Mnesia table that can be replicated
%% across multiple nodes in a distributed cache cluster.
%%
%% This module manages the registry only and does not manage
%% the lifecycle or state of cache element processes.
%% @end
%%%-------------------------------------------------------------------

-module(simple_cache_store).

-export([initialize/0, insert/2, lookup/1, delete/1]).

-record(key_to_pid, {key, pid}).

-type cache_key() :: term().
-type cache_pid() :: pid().
-type cache_node() :: node().
-type cache_nodes() :: [cache_node()].

-define(WAIT_FOR_TABLES, 5000).

%%====================================================================
%% API
%%====================================================================

%% @doc Initializes Mnesia table for cache storage.
-spec initialize() -> ok.
initialize() ->
    _ = mnesia:stop(),
    ok = mnesia:delete_schema([node()]),
    ok = mnesia:start(),
    CacheNodes = resource_discovery_server:get_resources(simple_cache),
    OtherCacheNodes = lists:delete(node(), CacheNodes),
    dynamic_db_init(OtherCacheNodes).

%% @doc Inserts or updates mapping from Key to Pid.
-spec insert(cache_key(), cache_pid()) -> ok.
insert(Key, Pid) ->
    mnesia:dirty_write(#key_to_pid{key = Key, pid = Pid}).

%% @doc Looks up cache element Pid by Key.
-spec lookup(cache_key()) -> {ok, cache_pid()} | {error, not_found}.
lookup(Key) ->
    case mnesia:dirty_read(key_to_pid, Key) of
        [{key_to_pid, Key, Pid}] ->
            case is_pid_alive(Pid) of
                true ->
                    {ok, Pid};
                false ->
                    {error, not_found}
            end;
        [] ->
            {error, not_found}
    end.

%% @doc Deletes all entries pointing to given Pid.
-spec delete(cache_pid()) -> ok.
delete(Pid) ->
    Records = mnesia:dirty_index_read(key_to_pid, Pid, #key_to_pid.pid),
    lists:foreach(fun mnesia:dirty_delete_object/1, Records),
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

-spec is_pid_alive(cache_pid()) -> boolean().
is_pid_alive(Pid) when node(Pid) =:= node() ->
    is_process_alive(Pid);
is_pid_alive(Pid) ->
    case lists:member(node(Pid), nodes()) of
        true ->
            rpc:call(node(Pid), erlang, is_process_alive, [Pid]) =:= true;
        false ->
            false
    end.

-spec dynamic_db_init(cache_nodes()) -> ok | {error, term()} | {timeout, [atom()]}.
dynamic_db_init([]) ->
    case mnesia:create_table(key_to_pid,
                             [{index, [pid]}, {attributes, record_info(fields, key_to_pid)}])
    of
        {atomic, ok} ->
            ok;
        {aborted, Reason} ->
            {error, Reason}
    end;
dynamic_db_init(CacheNodes) ->
    add_extra_nodes(CacheNodes).

-spec add_extra_nodes(cache_nodes()) -> ok | {error, term()} | {timeout, [atom()]}.
add_extra_nodes([]) ->
    {error, no_available_mnesia_nodes};
add_extra_nodes([Node | Nodes]) ->
    case mnesia:change_config(extra_db_nodes, [Node]) of
        {ok, [Node]} ->
            mnesia:add_table_copy(schema, node(), ram_copies),
            mnesia:add_table_copy(key_to_pid, node(), ram_copies),
            mnesia:wait_for_tables(
                mnesia:system_info(tables), ?WAIT_FOR_TABLES);
        _ ->
            add_extra_nodes(Nodes)
    end.
