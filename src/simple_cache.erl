%%%-------------------------------------------------------------------
%%% @doc
%%% Simple Cache API layer.
%%%
%%% Provides a thin interface over the cache system:
%%% - sc_store (key -> pid registry via ETS)
%%% - simple_cache_element (process-based value storage)
%%%
%%% This module contains no state and only orchestrates calls.
%%%-------------------------------------------------------------------
-module(simple_cache).

-export([insert/2, lookup/1, delete/1]).

%%%===================================================================
%%% API
%%%===================================================================
%%% @doc Inserts or updates a value in the cache..
-spec insert(term(), term()) ->
    ok | {error, term()}.
insert(Key, Value) ->
    case simple_cache_store:lookup(Key) of
        {ok, Pid} ->
            simple_cache_element:replace(Pid, Value);
        {error, not_found} ->
            case simple_cache_element:create(Value) of
                {ok, Pid} -> simple_cache_store:insert(Key, Pid);
                Error -> Error
            end
    end.

%%% @doc Retrieves a value from the cache by Key.
-spec lookup(term()) -> {ok, term()} | {error, not_found}.
lookup(Key) ->
    case simple_cache_store:lookup(Key) of
        {ok, Pid} -> simple_cache_element:fetch(Pid);
        Error -> Error
    end.

%%% @doc Deletes a cache entry by Key.
-spec delete(term()) -> ok.
delete(Key) ->
    case simple_cache_store:lookup(Key) of
        {ok, Pid} -> simple_cache_element:delete(Pid);
        _Error -> ok
    end.
