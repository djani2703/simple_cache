-module(simple_cache_cluster_tests).

-include_lib("eunit/include/eunit.hrl").

%% ============================================================
%% Setup / Cleanup
%% ============================================================

setup() ->
    simple_cache_test_helper:setup_cluster().

cleanup({PreviousWaitTime, PreviousContractNodes}) ->
    simple_cache_test_helper:cleanup_cluster({PreviousWaitTime, PreviousContractNodes}).

%% ============================================================
%% Tests
%% ============================================================

no_contact_nodes_configured() ->
    ok = application:unset_env(simple_cache, contract_nodes),
    ?assertEqual({error, no_contact_nodes_configured},
                 simple_cache_cluster:ensure_connected()).

no_contact_nodes_reachable() ->
    [_, Host] = string:split(atom_to_list(node()), "@"),
    UnreachableNode = list_to_atom("simple_cache_unreachable@" ++ Host),
    ?assertEqual({error, no_contact_nodes_reachable},
                 simple_cache_cluster:ensure_connected([UnreachableNode])).

connects_to_explicit_node() ->
    ?assertEqual(ok, simple_cache_cluster:ensure_connected([node()])).

connects_to_configured_node() ->
    ok = application:set_env(simple_cache, contract_nodes, [node()]),
    ?assertEqual(ok, simple_cache_cluster:ensure_connected()).

%% ============================================================
%% Test fixture
%% ============================================================

simple_cache_cluster_test_() ->
    {setup,
     fun setup/0,
     fun cleanup/1,
     [fun no_contact_nodes_configured/0,
      fun no_contact_nodes_reachable/0,
      fun connects_to_explicit_node/0,
      fun connects_to_configured_node/0]}.
