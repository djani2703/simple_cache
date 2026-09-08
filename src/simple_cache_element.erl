%%%-------------------------------------------------------------------
%% @doc
%% Simple Cache worker process.
%%
%% Stores a single value and automatically terminates
%% when its lease time expires.
%%
%% Each cache entry is represented by a dedicated gen_server process.
%% @end
%%%-------------------------------------------------------------------

-module(simple_cache_element).

-behaviour(gen_server).

-include_lib("kernel/include/logger.hrl").

%% API
-export([start_link/2, create/1, create/2, fetch/1, replace/2, delete/1]).
%% Gen Server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
         code_change/3]).

-define(DEFAULT_LEASE_TIME, 86400).

-type init_args() :: {term(), non_neg_integer()}.
-type state() ::
    #{lease_time := non_neg_integer(),
      start_time := integer(),
      value := term()}.

%%====================================================================
%% API
%%====================================================================

%% @doc Starts the simple cache worker process.
-spec start_link(term(), non_neg_integer()) -> {ok, pid()} | {error, term()}.
start_link(Value, LeaseTime) ->
    gen_server:start_link(?MODULE, {Value, LeaseTime}, []).

%% @doc Create the simple cache worker process by default lease time.
-spec create(term()) -> {ok, pid()} | {error, term()}.
create(Value) ->
    create(Value, ?DEFAULT_LEASE_TIME).

%% @doc Creates a cache worker process that stores Value for LeaseTime seconds.
-spec create(term(), non_neg_integer()) -> {ok, pid()} | {error, term()}.
create(Value, LeaseTime) ->
    simple_cache_sup:start_child(Value, LeaseTime).

%% @doc Returns the simple cache value.
-spec fetch(pid()) -> {ok, term()}.
fetch(Pid) ->
    gen_server:call(Pid, fetch).

%% @doc Replaces the cached value.
-spec replace(pid(), term()) -> ok.
replace(Pid, Value) ->
    gen_server:cast(Pid, {replace, Value}).

%% @doc Terminates the simple cache process.
-spec delete(pid()) -> ok.
delete(Pid) ->
    gen_server:cast(Pid, delete).

%%====================================================================
%% Gen Server callbacks
%%====================================================================

-spec init(init_args()) -> {ok, state(), timeout()}.
init({Value, LeaseTime}) ->
    State =
        #{lease_time => LeaseTime,
          start_time => erlang:monotonic_time(second),
          value => Value},
    RemainingTime = remaining_time(State),
    {ok, State, RemainingTime}.

-spec handle_call(term(), gen_server:from(), state()) ->
                     {reply, {ok, term()}, state(), timeout()}.
handle_call(fetch, _From, #{value := Value} = State) ->
    RemainingTime = remaining_time(State),
    {reply, {ok, Value}, State, RemainingTime}.

-spec handle_cast({replace, term()} | delete, state()) ->
                     {noreply, state(), timeout()} | {stop, normal, state()}.
handle_cast({replace, Value}, State) ->
    RemainingTime = remaining_time(State),
    {noreply, State#{value := Value}, RemainingTime};
handle_cast(delete, State) ->
    {stop, normal, State}.

-spec handle_info(term(), state()) -> {stop, normal, state()}.
handle_info(timeout, State) ->
    ?LOG_INFO("Cache entry process ~p expired", [self()]),
    {stop, normal, State}.

-spec terminate(term(), state()) -> ok.
terminate(_Reason, _State) ->
    ok.

-spec code_change(term(), state(), term()) -> {ok, state()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%====================================================================
%% Internal functions
%%====================================================================

-spec remaining_time(state()) -> timeout().
remaining_time(#{start_time := StartTime, lease_time := LeaseTime}) ->
    CurrentTime = erlang:monotonic_time(second),
    ElapsedTime = CurrentTime - StartTime,
    case LeaseTime - ElapsedTime of
        Time when Time =< 0 ->
            0;
        Time ->
            Time * 1000
    end.
