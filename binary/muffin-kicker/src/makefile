build: build/main.o build/menu_hard.o build/menu_easy.o build/menu_hard.o build/game_easy.o build/game_hard.o build/game_redacted.o
	ld65 --dbgfile muffin_kicker.dbg -C ld65.config -o muffin_kicker.nes build/menu_easy.o build/game_easy.o build/main.o
	ld65 --dbgfile interrupting_muffin_kicker.dbg -C ld65.config -o interrupting_muffin_kicker.nes build/menu_hard.o build/game_hard.o build/main.o
	ld65 -C ld65.config -o muffin_kicker_redacted.nes build/menu_easy.o build/game_redacted.o build/main.o
	ld65 -C ld65.config -o interrupting_muffin_kicker_redacted.nes build/menu_hard.o build/game_redacted.o build/main.o
	date +%r

build/main.o: src/main.s src/menu.i src/main.i chr.bin
	ca65 -g "src/main.s" -o build/main.o

build/menu_easy.o: src/menu.s src/menu.i src/main.i src/game.i
	ca65 -g "src/menu.s" -o build/menu_easy.o

build/menu_hard.o: src/menu.s src/menu.i src/main.i src/game.i
	ca65 -g "src/menu.s" -o build/menu_hard.o -DHARD_MODE

build/game_easy.o: src/game.s src/game.i src/main.i
	ca65 -g "src/game.s" -o build/game_easy.o
build/game_hard.o: src/game.s src/game.i src/main.i
	ca65 -g "src/game.s" -o build/game_hard.o -DHARD_MODE
build/game_redacted.o: src/game.s src/game.i src/main.i
	ca65 -g "src/game.s" -o build/game_redacted.o -DREDACT

clean:
	rm *muffin_kicker.nes &
	rm *.dbg &
	rm -r build/* &
	rm labels.txt &
