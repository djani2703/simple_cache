APP=simple_cache

SRC=src
EBIN=ebin
INCLUDE=include

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

shell:
	erl -pa $(EBIN)

run: all shell