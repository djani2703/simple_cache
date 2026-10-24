-module(simple_cache_discovery_tests).

-include_lib("eunit/include/eunit.hrl").

%% ============================================================
%% Setup / Cleanup
%% ============================================================

setup() ->
    simple_cache_test_helper:start_discovery_mock().

cleanup(Server) ->
    simple_cache_test_helper:stop_discovery_mock(Server).

%% ============================================================
%% Tests
%% ============================================================

registers_and_trades_local_resource() ->
    ?assertEqual(ok, simple_cache_discovery:initialize()),
    ?assertEqual([{add_local_resource, {simple_cache, node()}},
                  {add_target_resource, simple_cache},
                  trade_resources],
                 simple_cache_test_helper:discovery_requests()).

%% ============================================================
%% Test fixture
%% ============================================================

simple_cache_discovery_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     [{timeout, 10, fun registers_and_trades_local_resource/0}]}.
