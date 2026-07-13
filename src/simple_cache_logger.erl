%%%-------------------------------------------------------------------
%%% @doc
%%% Configures Erlang Logger for the simple_cache application.
%%%
%%% Logger configuration is read from the application environment under
%%% the logger key. The following options are supported:
%%%
%%% * enabled - Enables or disables logging.
%%% * primary_level - Sets the Logger primary log level.
%%% * format - Selects the log output format (new or old).
%%%
%%% If logging is disabled or the configuration is missing, the primary
%%% log level is set to none, effectively disabling log output.
%%%-------------------------------------------------------------------
-module(simple_cache_logger).

-export([
    configure/0, set_primary_level/1, set_handler_output/1, set_output_format/1, set_output_format/2
]).

-define(DEFAULT_HANDLER_ID, default).

-define(LOG_DIRECTORY, "log").
-define(LOG_FILE, "app.log").

-type output_format() :: modern | legacy.

%%%===================================================================
%%% API
%%%===================================================================
-spec configure() -> ok.
configure() ->
    case application:get_env(simple_cache, logger) of
        {ok, #{enabled := true, primary_level := PrimaryLevel, format := Format}} ->
            ok = set_primary_level(PrimaryLevel),
            ok = set_handler_output(?DEFAULT_HANDLER_ID),
            ok = set_output_format(Format);
        _Other ->
            set_primary_level(none)
    end.

-spec set_primary_level(logger:level() | none) -> ok.
set_primary_level(PrimaryLevel) ->
    logger:set_primary_config(level, PrimaryLevel).

-spec set_handler_output(logger:handler_id()) -> ok.
set_handler_output(HandlerId) ->
    ok = ensure_log_dir(),
    _ = logger:remove_handler(HandlerId),
    ok = logger:add_handler(
        HandlerId,
        logger_std_h,
        #{
            config => #{
                file => filename:join(?LOG_DIRECTORY, ?LOG_FILE)
            }
        }
    ).

-spec set_output_format(output_format()) -> ok.
set_output_format(Format) ->
    set_output_format(?DEFAULT_HANDLER_ID, Format).

-spec set_output_format(logger:handler_id(), output_format()) -> ok.
set_output_format(HandlerId, modern) ->
    logger:update_formatter_config(HandlerId, #{
        single_line => true, legacy_header => false
    });
set_output_format(HandlerId, legacy) ->
    logger:update_formatter_config(HandlerId, #{
        single_line => false, legacy_header => true
    }).

%%%===================================================================
%%% Internal functions
%%%===================================================================
-spec ensure_log_dir() -> ok.
ensure_log_dir() ->
    filelib:ensure_dir(filename:join(?LOG_DIRECTORY, ?LOG_FILE)),
    ok.
