%%%-------------------------------------------------------------------
%% @doc
%% Simple Cache Resource Discovery.
%%
%% This module coordinates resource registration and discovery
%% for the simple_cache application.
%%
%% It registers the local cache resource, declares the resource
%% types this node is interested in, and initiates resource exchange
%% with other nodes in the Erlang cluster.
%%
%% Resource discovery is delegated to resource_discovery_server.
%% This module does not manage the discovery server lifecycle.
%% @end
%%%-------------------------------------------------------------------

-module(simple_cache_discovery).

-export([initialize/0]).

-define(WAIT_FOR_RESOURCES, 2500).

%%====================================================================
%% API
%%====================================================================

%% @doc Registers the local cache resource and initiates resource discovery.
-spec initialize() -> ok.
initialize() ->
    ok = resource_discovery_server:add_local_resource(simple_cache, node()),
    ok = resource_discovery_server:add_target_resource(simple_cache),
    ok = resource_discovery_server:trade_resources(),
    timer:sleep(?WAIT_FOR_RESOURCES).
