-module(simple_cache_sup).

-behaviour(supervisor).

-export([start_link/0, start_child/2]).
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

start_child(Value, Timeout) ->
    ChildSpec = #{
        id => make_ref(),
        start => {simple_cache_element, start_link, [Value, Timeout]},
        restart => temporary,
        shutdown => brutal_kill,
        type => worker,
        modules => [simple_cache_element]
    },
    supervisor:start_child(?SERVER, ChildSpec).

init(_Args) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1,
        period => 1
    },
    {ok, {SupFlags, []}}.
