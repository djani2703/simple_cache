-module(simple_cache_element).

-behaviour(gen_server).

-export([start_link/2, create/1, create/2, fetch/1, replace/2, delete/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(DEFAULT_LEASE_TIME, 86400).

-record(state, {value, lease_time, start_time}).

% API
create(Value) ->
    create(Value, ?DEFAULT_LEASE_TIME).
start_link(Value, LeaseTime) ->
    gen_server:start_link(?MODULE, [Value, LeaseTime], []).

create(Value, LeaseTime) ->
    simple_cache_sup:start_child(Value, LeaseTime).

fetch(Pid) ->
    gen_server:call(Pid, fetch).

replace(Pid, Value) ->
    gen_server:cast(Pid, {replace, Value}).

delete(Pid) ->
    gen_server:cast(Pid, delete).

% Gen Server callbacks
init([Value, LeaseTime]) ->
    State = #state{
        lease_time = LeaseTime,
        start_time = erlang:monotonic_time(second),
        value = Value
    },
    RemainingTime = remaining_time(State),
    {ok, State, RemainingTime}.

handle_call(fetch, _From, #state{value = Value} = State) ->
    RemainingTime = remaining_time(State),
    {reply, {ok, Value}, State, RemainingTime}.

handle_cast({replace, Value}, State) ->
    RemainingTime = remaining_time(State),
    {noreply, State#state{value = Value}, RemainingTime};
handle_cast(delete, State) ->
    {stop, normal, State}.

handle_info(timeout, State) ->
    {stop, normal, State}.

terminate(_Reason, _State) ->
    % Need to implement simple_cache_store module and then uncomment it:
    % simple_cache_store:delete(self()),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

% Internal functions
remaining_time(#state{lease_time = infinity}) ->
    infinity;
remaining_time(#state{start_time = StartTime, lease_time = LeaseTime}) ->
    CurrentTime = erlang:monotonic_time(second),
    ElapsedTime = CurrentTime - StartTime,
    case LeaseTime - ElapsedTime of
        Time when Time =< 0 -> 0;
        Time -> Time * 1000
    end.