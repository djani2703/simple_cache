-module(simple_cache_tests).

-include_lib("eunit/include/eunit.hrl").

%% ============================================================
%% Setup / Cleanup
%% ============================================================

setup() ->
    application:ensure_started(simple_cache).

cleanup(_SetupResult) ->
    application:stop(simple_cache).

%% ============================================================
%% Tests
%% ============================================================

insert_and_lookup_cache_value() ->
    Key = "test_key",
    Value = "test_value",

    ?assertEqual(ok, simple_cache:insert(Key, Value)),
    ?assertEqual({ok, Value}, simple_cache:lookup(Key)).

insert_updates_existing_cache_value() ->
    Key = "test_key",
    OldValue = "old_test_value",
    NewValue = "new_test_value",

    simple_cache:insert(Key, OldValue),
    ?assertEqual({ok, OldValue}, simple_cache:lookup(Key)),

    simple_cache:insert(Key, NewValue),
    ?assertEqual({ok, NewValue}, simple_cache:lookup(Key)).

lookup_nonexistent_cache_value() ->
    ?assertEqual({error, not_found}, simple_cache:lookup("nonexistent_key")).

delete_cache_value() ->
    Key = "test_key",
    Value = "test_value",

    simple_cache:insert(Key, Value),
    ?assertEqual({ok, Value}, simple_cache:lookup(Key)),

    ?assertEqual(ok, simple_cache:delete(Key)),
    ?assertEqual({error, not_found}, simple_cache:lookup(Key)).

delete_nonexistent_cache_value() ->
    ?assertEqual(ok, simple_cache:delete("nonexistent_key")).

%% ============================================================
%% Test fixture
%% ============================================================

simple_cache_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     [fun insert_and_lookup_cache_value/0,
      fun insert_updates_existing_cache_value/0,
      fun lookup_nonexistent_cache_value/0,
      fun delete_cache_value/0,
      fun delete_nonexistent_cache_value/0]}.
