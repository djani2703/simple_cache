%%%-------------------------------------------------------------------
%% @doc
%% Cluster connectivity helper for simple_cache.
%%
%% Reads configured peer nodes from application environment, pings them,
%% and waits up to the configured interval for cluster membership to appear.
%%
%% The module is intentionally lightweight: it does not manage runtime
%% state and only coordinates node connectivity checks for startup.
%% @end
%%%-------------------------------------------------------------------

-module(simple_cache_cluster).

-export([ensure_connected/0, ensure_connected/1]).

-define(DEFAULT_CONTRACT_NODES, []).
-define(DEFAULT_WAIT_TIME, 6000).
-define(SLICES, 10).

%%====================================================================
%% API
%%====================================================================

%% @doc Connects to configured peers; errors if none are configured or reachable.
-spec ensure_connected() -> ok | {error, term()}.
ensure_connected() ->
    case config(contract_nodes, ?DEFAULT_CONTRACT_NODES) of
        [_ | _] = ConnectedNodes ->
            ensure_connected(ConnectedNodes);
        [] ->
            {error, no_contact_nodes_configured}
    end.

%% @doc Connects to the specified peers and waits for cluster membership to appear.
-spec ensure_connected(list()) -> ok | {error, term()}.
ensure_connected(ConnectedNodes) ->
    case [Node || Node <- ConnectedNodes, net_adm:ping(Node) =:= pong] of
        [_ | _] = PresentNodes ->
            CountNodes = length(PresentNodes),
            wait_for_nodes(CountNodes);
        [] ->
            {error, no_contact_nodes_reachable}
    end.

%%====================================================================
%% Internal functions
%%====================================================================

-spec wait_for_nodes(integer()) -> ok.
wait_for_nodes(CountNodes) ->
    WaitTime = config(cluster_connection_wait_time, ?DEFAULT_WAIT_TIME),
    SliceTime = round(WaitTime / ?SLICES),
    wait_for_nodes(CountNodes, SliceTime, ?SLICES).

-spec wait_for_nodes(integer(), integer(), integer()) -> ok.
wait_for_nodes(_CountNodes, _SliceTime, 0) ->
    ok;
wait_for_nodes(CountNodes, SliceTime, Slice) ->
    case length(nodes()) > CountNodes of
        true ->
            ok;
        false ->
            timer:sleep(SliceTime),
            wait_for_nodes(CountNodes, SliceTime, Slice - 1)
    end.

-spec config(atom(), term()) -> term().
config(Key, Default) ->
    application:get_env(simple_cache, Key, Default).
