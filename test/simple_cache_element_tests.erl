-module(simple_cache_element_tests).

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

create_by_default_lease_time() ->
    {ok, Pid} = simple_cache_element:create("test_value"),
    ?assert(is_process_alive(Pid)),
    gen_server:stop(Pid).

create_by_specified_lease_time() ->
    {ok, Pid} = simple_cache_element:create("test_value", 10),
    ?assert(is_process_alive(Pid)),

    gen_server:stop(Pid).

fetch_simple_cache_element_value() ->
    Value = "test_value",

    {ok, Pid} = simple_cache_element:create(Value),
    ?assertEqual({ok, Value}, simple_cache_element:fetch(Pid)),

    gen_server:stop(Pid).

replace_simple_cache_element_value() ->
    OldValue = "old_test_value",
    NewValue = "new_test_value",

    {ok, Pid} = simple_cache_element:create(OldValue),
    ?assertEqual({ok, OldValue}, simple_cache_element:fetch(Pid)),

    simple_cache_element:replace(Pid, NewValue),
    ?assertEqual({ok, NewValue}, simple_cache_element:fetch(Pid)),

    gen_server:stop(Pid).

delete_simple_cache_element() ->
    {ok, Pid} = simple_cache_element:create("test_value"),
    ?assert(is_process_alive(Pid)),

    simple_cache_element:delete(Pid),
    ?assertNot(is_process_alive(Pid)).

%% ============================================================
%% Test fixture
%% ============================================================

simple_cache_element_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     [fun create_by_default_lease_time/0,
      fun create_by_specified_lease_time/0,
      fun fetch_simple_cache_element_value/0,
      fun replace_simple_cache_element_value/0,
      fun delete_simple_cache_element/0]}.
