-module(simple_cache_store_tests).

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

initialize_simple_cache_store() ->
    ?assertNotEqual(undefined, ets:info(simple_cache_store)).

insert_and_lookup_cache_element() ->
    Key = "test_key",
    Pid = self(),

    ?assertEqual(ok, simple_cache_store:insert(Key, Pid)),
    ?assertEqual({ok, Pid}, simple_cache_store:lookup(Key)).

lookup_nonexistent_cache_element() ->
    ?assertEqual({error, not_found}, simple_cache_store:lookup("nonexistent_key")).

delete_cache_elements_by_pid() ->
    Pid = self(),

    simple_cache_store:insert("key_1", Pid),
    simple_cache_store:insert("key_2", Pid),

    ?assertEqual({ok, Pid}, simple_cache_store:lookup("key_1")),
    ?assertEqual({ok, Pid}, simple_cache_store:lookup("key_2")),

    ?assertEqual(ok, simple_cache_store:delete(Pid)),

    ?assertEqual({error, not_found}, simple_cache_store:lookup("key_1")),
    ?assertEqual({error, not_found}, simple_cache_store:lookup("key_2")).

delete_nonexistent_pid() ->
    ?assertEqual(ok, simple_cache_store:delete(self())).

%% ============================================================
%% Test fixture
%% ============================================================

simple_cache_store_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     [fun initialize_simple_cache_store/0,
      fun insert_and_lookup_cache_element/0,
      fun lookup_nonexistent_cache_element/0,
      fun delete_cache_elements_by_pid/0,
      fun delete_nonexistent_pid/0]}.
