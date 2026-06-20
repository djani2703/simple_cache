%%%-------------------------------------------------------------------
%%% @doc
%%% Simple Cache OTP application.
%%%
%%% This application starts the supervision tree for the simple_cache system.
%%% The system is based on a supervisor that manages cache worker processes,
%%% where each cache entry is represented by a separate gen_server process.
%%%
%%% The application itself does not manage state directly; it only initializes
%%% and delegates control to the top-level supervisor.
%%%-------------------------------------------------------------------
-module(simple_cache_app).

-behaviour(application).

-export([start/2, stop/1]).

-spec start(application:start_type(), term()) ->
    {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    simple_cache_sup:start_link().

-spec stop(term()) -> ok.
stop(_State) ->
    ok.
