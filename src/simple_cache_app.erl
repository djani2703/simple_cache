%%%-------------------------------------------------------------------
%% @doc
%% Simple Cache OTP application.
%%
%% On startup, the application configures logging, connects to the cache
%% cluster, initializes resource discovery and the Mnesia store, then starts
%% the supervisor for cache worker processes.
%% @end
%%%-------------------------------------------------------------------

-module(simple_cache_app).

-behaviour(application).

-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

%% @doc Starts the simple cache supervision tree.
-spec start(application:start_type(), term()) -> {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    ok = initialize_application(),
    simple_cache_sup:start_link().

%% @doc Stops the simple cache application.
-spec stop(term()) -> ok.
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

-spec initialize_application() -> ok.
initialize_application() ->
    ok = simple_cache_logger:configure(),
    ok = simple_cache_cluster:ensure_connected(),
    ok = simple_cache_discovery:initialize(),
    ok = simple_cache_store:initialize().
