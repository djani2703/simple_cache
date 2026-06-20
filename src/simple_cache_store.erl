%%%-------------------------------------------------------------------
%%% @doc
%%% Simple Cache Store (ETS registry).
%%%
%%% This module maintains a mapping between cache keys and
%%% cache element process PIDs.
%%%
%%% It is a thin wrapper over ETS and does not manage lifecycle
%%% of cache elements.
%%%-------------------------------------------------------------------
-module(simple_cache_store).

-export([init/0, insert/2, lookup/1, delete/1]).

-define(TABLE_ID, ?MODULE).

%%%===================================================================
%%% API
%%%===================================================================
%%% @doc Initializes ETS table for cache storage.
-spec init() -> ok.
init() ->
    case ets:info(?TABLE_ID) of
        undefined ->
            ets:new(?TABLE_ID, [public, named_table]),
            ok;
        _Tid ->
            ok
    end.

%%% @doc Inserts or updates mapping from Key to Pid.
-spec insert(term(), pid()) -> ok.
insert(Key, Pid) ->
    ets:insert(?TABLE_ID, {Key, Pid}),
    ok.

%%% @doc Looks up cache element PID by Key.
-spec lookup(term()) -> {ok, pid()} | {error, not_found}.
lookup(Key) ->
    case ets:lookup(?TABLE_ID, Key) of
        [{Key, Pid}] -> {ok, Pid};
        [] -> {error, not_found}
    end.

%%% @doc Deletes all entries pointing to given PID.
-spec delete(pid()) -> true.
delete(Pid) ->
    ets:match_delete(?TABLE_ID, {'_', Pid}).
