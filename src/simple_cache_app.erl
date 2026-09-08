%%--------------------------------------------------------------------
%% @doc
%% Simple Cache OTP application.
%%
%% This application starts the supervision tree for the simple_cache system.
%% The system is based on a supervisor that manages cache worker processes,
%% where each cache entry is represented by a separate gen_server process.
%%
%% The application itself does not manage state directly; it only starts
%% the top-level supervisor.
%% @end
%%--------------------------------------------------------------------

-module(simple_cache_app).

-behaviour(application).

-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

%% @doc Starts the simple cache supervision tree.
-spec start(application:start_type(), term()) -> {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    ok = prepare_application(),
    simple_cache_sup:start_link().

%% @doc Stops the simple cache application.
-spec stop(term()) -> ok.
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================

prepare_application() ->
    ok = simple_cache_store:init(),
    ok.
