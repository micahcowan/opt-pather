# opt-pather

It's risky to blindly run `sudo make install` if you don't really understand what someone's Makefile is going to do on your system - and sometimes, you don't even have root access on your system anyway.

In many cases, you can run `make install DESTDIR=...` to install someplace else - but then you have to go to the bother of setting up your `PATH` variable, and maybe other things like `MANPATH`. If the software provides libraries you want to use, then you'd need to add `LD_LIBRARY_PATH` as well. Doing this every time you install something you don't want to be system-wide can get to be a pain.

Enter **opt-pather**! It's a shell script designed to be run from your `~/.profile`, `~/.bashrc`, `~/.kshrc`, `~/.zshrc`, etc, to set up vars like `PATH`, `MANPATH`, etc., according to what lives under `~/opt/`. On load, it scans `~/opt/` for installed software, and automatically sets up your environment to find and use the things that are there. Just installed something and want to set up your currently-running shell's `PATH` variable? No problem! Just run the **repath** command (shell function) to recalculate those variables, and you're good to go!

The script also takes care not to create duplicate entries when run multiple times (say, in a subshell).
