-- Initialize Starship prompt in CMD via Clink
load(io.popen('starship init cmd'):read("*a"))()
