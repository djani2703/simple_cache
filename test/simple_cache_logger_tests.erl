-module(simple_cache_logger_tests).

-include_lib("eunit/include/eunit.hrl").

%% ============================================================
%% Setup / Cleanup
%% ============================================================

setup() ->
    {application:get_env(simple_cache, logger), maps:get(level, logger:get_primary_config())}.

cleanup({PreviousConfig, PreviousLevel}) ->
    restore_logger_config(PreviousConfig),
    ok = simple_cache_logger:set_primary_level(PreviousLevel).

restore_logger_config({ok, Config}) ->
    ok = application:set_env(simple_cache, logger, Config);
restore_logger_config(undefined) ->
    ok = application:unset_env(simple_cache, logger).

%% ============================================================
%% Tests
%% ============================================================

configure_without_config_disables_logging() ->
    application:unset_env(simple_cache, logger),

    ?assertEqual(ok, simple_cache_logger:configure()),

    Config = logger:get_primary_config(),
    ?assertEqual(none, maps:get(level, Config)).

set_primary_level_test() ->
    ?assertEqual(ok, simple_cache_logger:set_primary_level(info)),

    Config = logger:get_primary_config(),
    ?assertEqual(info, maps:get(level, Config)).

%% ============================================================
%% Test fixture
%% ============================================================

simple_cache_logger_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     [fun configure_without_config_disables_logging/0, fun set_primary_level_test/0]}.
