### Shell functions for manipulating PATH, and PATH-like variables.

# path_shift(): removes the first path from the variable named (PATH, if
# unspecified)
#
# Example:
#
# $ echo "$PATH"
# /usr/local/bin:/usr/bin
# $ path_shift
# $ echo "$PATH"
# /usr/bin
#
path_shift() {
    _path_get_var "$@"
    if _var_exists "${_var}"
    then
        eval "OLD_${_var}=\${${_var}}"
        eval "${_var}=\$(echo \"\${${_var}}\" | sed 's/^[^:]*://')"
    fi
    if [ "${PATHFNS_VERBOSE+yes}" = yes ]
    then
        path_current "${_var-}"
    fi
}

# path_unshift(): prepends a path to a list of paths.
#
# If two arguments are specified, the first is the name of a PATH-like
# variable, and the second is the path to prepend. If only one argument
# is specified, PATH is used, and the argument is the path to prepend.
#
# Example:
# $ echo "$PATH"
# /usr/bin
# $ path_unshift /usr/local/bin
# $ echo "$PATH"
# /usr/local/bin:/usr/bin
#
# $ echo "$MANPATH"
# /usr/share/man
# $ path_unshift MANPATH /usr/man
# $ echo "$MANPATH"
# /usr/man:/usr/share/man
#
path_unshift() {
    _path_get_var_val "$@"
    if _var_exists "${_var}"
    then
        eval "OLD_${_var}=\${${_var}}"
        if eval "[ \"x\$${_var}\" = 'x' ]"
        then
            eval "${_var}=\"${_val}\""
        else
            eval "${_var}=\"${_val}:\$${_var}\""
        fi
    else
        eval "${_var}=\"${_val}\""
        eval "export ${_var}"
    fi
    if [ "${PATHFNS_VERBOSE+yes}" = yes ]
    then
        path_current "${_var-}"
    fi
}

# path_print(): print the named path-list variable (PATH if
# unspecified), substituting newlines for colons (:) for readability
#
# Example:
# $ echo "$PATH"
# /home/micah/bin:/usr/local/bin:/usr/bin
# $ print_path
# /home/micah/bin
# /usr/local/bin
# /usr/bin
# 
path_print() {
    _path_get_var "$@"
    eval echo "\${${_var}}" | sed "$(printf '%b' 's/:/\\\n/g')"
}

path_current() {
    _path_get_var "$@"
    eval echo "OLD_${_var}=\${OLD_${_var}-}"
    eval echo "${_var}=\${${_var}-}"
    unset _var _val
}

_var_exists() {
    eval [ "\"x\${${1}-__none}\"" != x__none ]
}

_path_get_var() {
    _var="${1-PATH}"
}

_path_get_var_val() {
    if [ "${2-__none}" != __none ]
    then
        # pathvar value
        _path_get_var "$@"
        shift
    else
        # value
        _var=PATH
    fi
    _val=$1
}

# TODO: path_push, path_pop
# Install paths for everything installed to and ~/opt/. Saves me
# having to add PATHs for new software I install from source.

### repath: function to automatically add appropriate things found in
#   ~/opt/*/ to various useful PATH-style variables, to ensure that
#   binaries, manpages, libraries, etc, are available in the execution
#   environment of any programs run by this shell.
#
#   When new things are added under ~/opt, just run "repath" to add
#   them into the currently-running shell.

repath() {
    path_var_names='PATH MANPATH INFOPATH LD_LIBRARY_PATH DYLD_LIBRARY_PATH PYTHONPATH PKG_CONFIG_PATH'

    # This bit of magic allows us to save away the original PATH from
    # before we messed with it. Subsequent evaluations of this file will
    # first restore the original PATH, and then apply whatever
    # manipulations (such as those found in "~/opt"), to avoid
    # cluttering the PATH on successive evaluations.

    for var in $path_var_names
    do
        if eval "[ \"x\${MJC_ORIG_${var}-__empty__}\" = 'x__empty__' ]"
        then
            eval "export MJC_ORIG_${var}=\"\$${var}\""
        else
            eval "export ${var}=\"\$MJC_ORIG_${var}\""
        fi
    done

    # Initial values for certain paths.
    path_unshift MANPATH \
        $HOME/share/man:/usr/local/share/man:/usr/man:/usr/share/man
    path_unshift INFOPATH $HOME/share/info:/usr/share/info:
        # Final : tells info/emacs to tack on default dirs too
    path_unshift "/usr/local/bin:/usr/sbin:/sbin"

    for dir in ~/opt/*
    do
        case dir in
            ~/opt/\*)
                ;;
            *)
                if test ! -f "$dir"/.no-install
                then
                    [ -d "$dir"/bin ] && path_unshift PATH "$dir/bin"
                    [ -d "$dir"/man ] && path_unshift MANPATH "$dir/man"
                    [ -d "$dir"/share/man ] &&
                        path_unshift MANPATH "$dir/share/man"
                    [ -d "$dir"/info ] && path_unshift INFOPATH "$dir/info"
                    [ -d "$dir"/share/info ] &&
                        path_unshift INFOPATH "$dir/share/info"

                    [ -d "$dir"/lib ] &&
                        path_unshift LD_LIBRARY_PATH "$dir"/lib
                    [ -d "$dir"/lib ] &&
                        path_unshift DYLD_LIBRARY_PATH "$dir"/lib

                    # Probaby should only use one of these, depending on the
                    # current architecture. So far, though, I only ever have
                    # one or the other.
                    [ -d "$dir"/lib/python ] &&
                        path_unshift PYTHONPATH "$dir/lib/python"
                    [ -d "$dir"/lib64/python ] &&
                        path_unshift PYTHONPATH "$dir/lib64/python"

                    [ -d "$dir"/lib/pkgconfig ] &&
                        path_unshift PKG_CONFIG_PATH "$dir/lib/pkgconfig"
                fi
        esac
    done

    path_unshift "$HOME/bin"
}

repath
