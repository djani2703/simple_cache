APP=simple_cache

CONFIG=config/sys
EBIN=ebin
INCLUDE=include
SRC=src

ERLC=erlc
ERL_FLAGS=-I $(INCLUDE) -o $(EBIN) +debug_info -Wall

ERL_SOURCES=$(wildcard $(SRC)/*.erl)

all: compile app

compile:
	mkdir -p $(EBIN)
	$(ERLC) $(ERL_FLAGS) $(ERL_SOURCES)

app:
	cp $(SRC)/$(APP).app.src $(EBIN)/$(APP).app

clean:
	rm -rf $(EBIN)

docs:
	erl -noshell -eval "edoc:application(simple_cache, \".\", [{dir, \"doc\"}]), halt()."

shell:
	erl -pa $(EBIN) -config $(CONFIG)

run: all shell