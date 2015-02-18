#!/usr/bin/env bash

set -eux

set_opts() {
    while [[ $# > 1 ]] ; do
        key="$1"

        case $key in
            -u|--upstream)
            export UPSTREAM="$2"
            shift
            ;;
            -f|--fork)
            export FORK="$2"
            shift
            ;;
            --force)
            export FORCE="true"
            ;;
            *)
            export MODULES_PATHS="$@"
            break
            ;;
        esac
        shift
    done
}

set_remote() {
    local remote_name="$1"
    local remote_url="$2"
    if git remote -v | grep $remote_name 1>/dev/null ; then # remote set; make sure it's set correctly
        git remote set-url $remote_name $remote_url
    else # remote unset
        git remote add $remote_name $remote_url
    fi
}
set_upstream_remote() {
    local remote="$1"
    set_remote 'upstream' $remote
}

update_local_repos() {
    for mod in $MODULES_PATHS ; do
        local remote=${UPSTREAM}/$(basename $mod)
        if [ -d $mod ] ; then
            pushd $mod
                set_upstream_remote $remote
                git checkout master
                git pull $remote master
            popd
        else
            git clone $remote $mod
            pushd $mod
                git remote rename origin upstream
            popd
        fi
    done
}

set_fork_remote() {
    local remote="$1"
    set_remote 'fork' $remote
}

update_remote_fork() {
    for mod in $MODULES_PATHS ; do
        pushd $mod
            remote=${FORK}/$(basename $mod)
            set_fork_remote $remote
            git remote -v
            if [ $FORCE == "true" ] ; then
                echo "YOU ARE TRYING TO FORCE PUSH TO REMOTE $remote ON BRANCH master"
                echo "Waiting for five seconds so you can be sure that's what you wanted."
                sleep 5
                git push -f fork master
            else
                git push fork master
            fi
        popd
    done
}

main() {
    set_opts $@
    update_local_repos
    update_remote_fork
}

main $@
