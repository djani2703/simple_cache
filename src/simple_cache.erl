%%--------------------------------------------------------------------
%% @doc
%% Simple Cache API layer.
%%
%% Provides a public interface for storing, retrieving, and deleting
%% cached values.
%%
%% The cache consists of:
%% - simple_cache_store - key to process PID registry via ETS
%% - simple_cache_element - process-based value storage with lease time
%%
%% This module contains no state and orchestrates calls between
%% the cache store and cache element processes.
%% @end
%%--------------------------------------------------------------------

-module(simple_cache).

-export([insert/2, insert/3, lookup/1, delete/1]).

-define(DEFAULT_LEASE_TIME, 86400).

%%====================================================================
%% API
%%====================================================================

%% @doc Inserts or updates a value in the cache using the default lease time.
-spec insert(term(), term()) -> ok | {error, term()}.
insert(Key, Value) ->
    insert(Key, Value, ?DEFAULT_LEASE_TIME).

%% @doc Inserts or updates a value in the cache using the specified lease time in seconds.
-spec insert(term(), term(), non_neg_integer()) -> ok | {error, term()}.
insert(Key, Value, LeaseTime) ->
    case simple_cache_store:lookup(Key) of
        {ok, Pid} ->
            simple_cache_element:replace(Pid, Value);
        {error, not_found} ->
            case simple_cache_element:create(Value, LeaseTime) of
                {ok, Pid} ->
                    simple_cache_store:insert(Key, Pid);
                Error ->
                    Error
            end
    end.

%% @doc Retrieves a value from the cache by Key.
-spec lookup(term()) -> {ok, term()} | {error, not_found}.
lookup(Key) ->
    case simple_cache_store:lookup(Key) of
        {ok, Pid} ->
            simple_cache_element:fetch(Pid);
        Error ->
            Error
    end.

%% @doc Deletes a cache entry by Key.
-spec delete(term()) -> ok.
delete(Key) ->
    case simple_cache_store:lookup(Key) of
        {ok, Pid} ->
            ok = simple_cache_element:delete(Pid),
            ok = simple_cache_store:delete(Pid);
        _Error ->
            ok
    end.
