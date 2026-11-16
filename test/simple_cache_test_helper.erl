-module(simple_cache_test_helper).

-export([setup_cluster/0, cleanup_cluster/1, start_storage/0, start_cache/0,
         start_supervisor/0, stop_started_apps/1, stop_cache/1, stop_supervisor/1,
         start_discovery_mock/0, stop_discovery_mock/1, discovery_requests/0]).

setup_cluster() ->
    ok = ensure_test_node(),

    PreviousWaitTime = application:get_env(simple_cache, cluster_connection_wait_time),
    PreviousContractNodes = application:get_env(simple_cache, contract_nodes),

    ok = application:set_env(simple_cache, cluster_connection_wait_time, 0),

    {PreviousWaitTime, PreviousContractNodes}.

cleanup_cluster({PreviousWaitTime, PreviousContractNodes}) ->
    restore_env(cluster_connection_wait_time, PreviousWaitTime),
    restore_env(contract_nodes, PreviousContractNodes).

start_storage() ->
    ok = ensure_test_node(),

    {ok, DiscoveryApps} = application:ensure_all_started(resource_discovery),
    {ok, MnesiaApps} = application:ensure_all_started(mnesia),

    ok = simple_cache_store:initialize(),

    DiscoveryApps ++ MnesiaApps.

start_cache() ->
    StartedApps = start_storage(),
    Supervisor = start_supervisor(),
    {Supervisor, StartedApps}.

start_supervisor() ->
    {ok, Supervisor} = simple_cache_sup:start_link(),
    unlink(Supervisor),
    Supervisor.

stop_started_apps(StartedApps) ->
    lists:foreach(fun(App) -> ok = application:stop(App) end, lists:reverse(StartedApps)).

stop_cache({Supervisor, StartedApps}) ->
    ok = stop_supervisor(Supervisor),
    ok = stop_started_apps(StartedApps).

stop_supervisor(Supervisor) ->
    gen_server:stop(Supervisor).

start_discovery_mock() ->
    Server = spawn(fun() -> discovery_mock([]) end),
    true = register(resource_discovery_server, Server),
    Server.

stop_discovery_mock(Server) ->
    true = unregister(resource_discovery_server),
    Server ! stop,
    ok.

discovery_requests() ->
    Ref = make_ref(),
    whereis(resource_discovery_server) ! {get_requests, self(), Ref},
    receive
        {Ref, Requests} ->
            Requests
    after 1000 ->
        error(missing_resource_discovery_calls)
    end.

ensure_test_node() ->
    case net_kernel:start([simple_cache_test, shortnames]) of
        {ok, _Pid} ->
            ok;
        {error, {already_started, _Pid}} ->
            ok;
        {error, Reason} ->
            error({cannot_start_test_node, Reason})
    end.

restore_env(Key, {ok, Value}) ->
    ok = application:set_env(simple_cache, Key, Value);
restore_env(Key, undefined) ->
    ok = application:unset_env(simple_cache, Key).

discovery_mock(Requests) ->
    receive
        {'$gen_call', {From, Tag}, Request} ->
            From ! {Tag, ok},
            discovery_mock([Request | Requests]);
        {'$gen_cast', Request} ->
            discovery_mock([Request | Requests]);
        {get_requests, From, Tag} ->
            From ! {Tag, lists:reverse(Requests)},
            discovery_mock(Requests);
        stop ->
            ok
    end.
