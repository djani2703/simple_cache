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

-include_lib("kernel/include/logger.hrl").

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
            ?LOG_INFO("Replacing cached value for key ~p (pid=~p)", [Key, Pid]),
            simple_cache_element:replace(Pid, Value);
        {error, not_found} ->
            case simple_cache_element:create(Value, LeaseTime) of
                {ok, Pid} ->
                    ?LOG_INFO("Cache entry created for key ~p (pid=~p)", [Key, Pid]),
                    simple_cache_store:insert(Key, Pid);
                Error ->
                    ?LOG_ERROR("Failed to create cache entry for key ~p: ~p", [Key, Error]),
                    Error
            end
    end.

%% @doc Retrieves a value from the cache by Key.
-spec lookup(term()) -> {ok, term()} | {error, not_found}.
lookup(Key) ->
    case simple_cache_store:lookup(Key) of
        {ok, Pid} ->
            ?LOG_DEBUG("Cache lookup succeeded for key ~p (pid=~p)", [Key, Pid]),
            simple_cache_element:fetch(Pid);
        Error ->
            ?LOG_DEBUG("Cache miss for key ~p", [Key]),
            Error
    end.

%% @doc Deletes a cache entry by Key.
-spec delete(term()) -> ok.
delete(Key) ->
    case simple_cache_store:lookup(Key) of
        {ok, Pid} ->
            ?LOG_INFO("Deleting cache entry for key ~p (pid=~p)", [Key, Pid]),
            ok = simple_cache_element:delete(Pid),
            ok = simple_cache_store:delete(Pid);
        _Error ->
            ?LOG_DEBUG("Delete ignored: key ~p does not exist", [Key]),
            ok
    end.
