%%%-------------------------------------------------------------------
%%% @doc
%%% Simple Cache Supervisor.
%%%
%%% This supervisor manages cache worker processes where each cache entry
%%% is represented by a dedicated gen_server process.
%%%
%%% The supervisor uses a one_for_one strategy and allows dynamic creation
%%% of cache workers via start_child/2.
%%%-------------------------------------------------------------------
-module(simple_cache_sup).

-behaviour(supervisor).

-export([start_link/0, start_child/2]).
-export([init/1]).

-define(SERVER, ?MODULE).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

-spec start_child(term(), non_neg_integer()) ->
    supervisor:startchild_ret().
start_child(Value, LeaseTime) ->
    ChildSpec = #{
        id => make_ref(),
        start => {simple_cache_element, start_link, [Value, LeaseTime]},
        restart => temporary,
        shutdown => brutal_kill,
        type => worker,
        modules => [simple_cache_element]
    },
    supervisor:start_child(?SERVER, ChildSpec).

-spec init(term()) ->
    {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init(_Args) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1,
        period => 1
    },
    {ok, {SupFlags, []}}.
