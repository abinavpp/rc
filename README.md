## Deploy

    stow --no-folding -d ~/rc -t ~ home
    cd ~/rc/sysroot
    find . -type f | sudo rsync -rlptK --no-owner --no-group --files-from=- . /

## Synchronize

`home` is symlinked - nothing to run. A new file under `home` is live only
after the deploy stow reruns.

`sysroot`, after changing a tracked file under `/`:

    cd ~/rc/sysroot && find . -type f | rsync -a --files-from=- / .

## Check

Links an app broke by rewriting its config in place (write temp, rename):

    git -C ~/rc ls-files home | sed 's|^home/||' |
      while read -r f; do [ -L "$HOME/$f" ] || echo "detached: $f"; done
