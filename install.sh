#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

a2pi_whoami() {
   echo "PrettyIndex"
}

a2pi_version() {
   echo "v1.0.0"
}

a2pi_log() {
   echo "    $(a2pi_whoami): $1"
}

a2pi_err() {
   echo >&2 "    $(a2pi_whoami): $1"
}

a2pi_bye() {
   echo
   echo "=========================================================================="
   echo
}

a2pi_has() {
   type "$1" > /dev/null 2>&1
}

a2pi_exec(){
   command "$@" > /dev/null 2>&1
}

a2pi_euid() {
   if [ -n "$EUID" ]; then
      printf %s "${EUID}"
   else
      printf %s $(id -u)
   fi
}

a2pi_install_dir() {
   if [ -n "$A2PI_DIR" ]; then
      printf %s "${A2PI_DIR}"
   else
      printf %s "/usr/lib/apache2/PrettyIndex"
   fi
}

#
# Outputs the path for the contents to be downloaded depending on:
# The method used ("targz" or "zip" or "git", defaults to "git")
#
a2pi_source() {
   local A2PI_METHOD
   A2PI_METHOD="$1"
   local A2PI_SOURCE_URL
   if [ "_$A2PI_METHOD" = "_targz" ]; then
      A2PI_SOURCE_URL="https://github.com/webcdn/PrettyIndex/archive/$(a2pi_version).tar.gz"
   elif [ "_$A2PI_METHOD" = "_zip" ]; then
      A2PI_SOURCE_URL="https://github.com/webcdn/PrettyIndex/archive/$(a2pi_version).zip"
   elif [ "_$A2PI_METHOD" = "_git" ] || [ -z "$A2PI_METHOD" ]; then
      A2PI_SOURCE_URL="https://github.com/webcdn/PrettyIndex.git"
   else
      echo >&2 "Unexpected value \"$A2PI_METHOD\" for (a2pi_source)"
      return 1
   fi
   echo "$A2PI_SOURCE_URL"
}

a2pi_download() {
   if a2pi_has "curl"; then
      curl --compressed -q "$@"
   elif a2pi_has "wget"; then
      # Emulate curl with wget
      ARGS=$(echo "$*" | command sed -e 's/--progress-bar /--progress=bar /' \
                                    -e 's/-L //' \
                                    -e 's/--compressed //' \
                                    -e 's/-I /--server-response /' \
                                    -e 's/-s /-q /' \
                                    -e 's/-o /-O /' \
                                    -e 's/-C - /-c /')
      eval wget $ARGS
   fi
}

install_a2pi_from_git() {
  local INSTALL_DIR
  INSTALL_DIR="$(a2pi_install_dir)"

  if [ -d "$INSTALL_DIR/.git" ]; then
    a2pi_log "PrettyIndex is already installed in $INSTALL_DIR, trying to update using git"
    command printf '\r=> '
    command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" fetch origin tag "$(a2pi_version)" --depth=1 2> /dev/null || {
      a2pi_err "Failed to update PrettyIndex, run 'git fetch' in $INSTALL_DIR yourself."
      a2pi_bye
      exit 1
    }
  else
    # Cloning to $INSTALL_DIR
    a2pi_log "Downloading PrettyIndex from git to '$INSTALL_DIR'"
    command printf '\r=> '
    mkdir -p "${INSTALL_DIR}"
    if [ "$(ls -A "${INSTALL_DIR}")" ]; then
      command git init "${INSTALL_DIR}" || {
        a2pi_err 'Failed to initialize PrettyIndex repo. Please report this!'
        a2pi_bye
        exit 2
      }
      command git --git-dir="${INSTALL_DIR}/.git" remote add origin "$(a2pi_source)" 2> /dev/null \
        || command git --git-dir="${INSTALL_DIR}/.git" remote set-url origin "$(a2pi_source)" || {
        a2pi_err 'Failed to add remote "origin" (or set the URL). Please report this!'
        a2pi_bye
        exit 2
      }
      command git --git-dir="${INSTALL_DIR}/.git" fetch origin tag "$(a2pi_version)" --depth=1 || {
        a2pi_err 'Failed to fetch origin with tags. Please report this!'
        a2pi_bye
        exit 2
      }
    else
      command git -c advice.detachedHead=false clone "$(a2pi_source)" -b "$(a2pi_version)" --depth=1 "${INSTALL_DIR}" || {
        a2pi_err 'Failed to clone PrettyIndex repo. Please report this!'
        a2pi_bye
        exit 2
      }
    fi
  fi
  command git -c advice.detachedHead=false --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" checkout -f --quiet "$(a2pi_version)"
  if [ -n "$(command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" show-ref refs/heads/master)" ]; then
    if command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet 2>/dev/null; then
      command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch --quiet -D master >/dev/null 2>&1
    else
      a2pi_err "Your version of git is out of date. Please update it!"
      command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" branch -D master >/dev/null 2>&1
    fi
  fi

  a2pi_log "Compressing and cleaning up git repository"
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" reflog expire --expire=now --all; then
    a2pi_err "Your version of git is out of date. Please update it!"
  fi
  if ! command git --git-dir="$INSTALL_DIR"/.git --work-tree="$INSTALL_DIR" gc --auto --aggressive --prune=now ; then
    a2pi_err "Your version of git is out of date. Please update it!"
  fi
  return
}

install_a2pi_using() {
   local INSTALL_METHOD
   INSTALL_METHOD="$1"

   local INSTALL_DIR
   INSTALL_DIR="$(a2pi_install_dir)"

   # Downloading to $INSTALL_DIR
   if [ -e "$INSTALL_DIR" ]; then
      a2pi_log "Already installed, trying to update $(a2pi_version) via $INSTALL_METHOD"
   else
      a2pi_log "Downloading $(a2pi_whoami)_$(a2pi_version) via $INSTALL_METHOD"
   fi


   if [ "${INSTALL_METHOD}" = 'tar' ]; then
      mkdir -p "$INSTALL_DIR"

      a2pi_download -s -L "$(a2pi_source targz)" -o "$INSTALL_DIR.tar.gz" || {
         a2pi_err "Failed to download $(a2pi_whoami).tar.gz"
         return 1
      } &&
      tar -xzf "$INSTALL_DIR.tar.gz" -C "$INSTALL_DIR" --strip-components=1 || {
         a2pi_err "Failed to extract $(a2pi_whoami).tar.gz"
         return 2
      } &&
      rm "$INSTALL_DIR.tar.gz" || {
         a2pi_err "Failed to delete $(a2pi_whoami).tar.gz"
         return 3
      }

   elif [ "${INSTALL_METHOD}" = 'zip' ]; then
      a2pi_download -s -L "$(a2pi_source zip)" -o "$INSTALL_DIR.zip" || {
         a2pi_err "Failed to download $(a2pi_whoami).zip"
         return 1
      } &&
      unzip -qo "$INSTALL_DIR.zip" || {
         a2pi_err "Failed to extract $(a2pi_whoami).zip"
         return 2
      } &&
      mv "$INSTALL_DIR-"* "$INSTALL_DIR" || {
         a2pi_err "Failed to modify directory $(a2pi_whoami)"
         return 2
      } &&
      rm "$INSTALL_DIR.zip" || {
         a2pi_err "Failed to delete $(a2pi_whoami).zip"
         return 3
      }
   fi

   for job in $(jobs -p | command sort)
   do
      wait "$job" || return $?
   done
}

a2pi_do_install() {
   echo
   echo "=========================================================================="
   echo "#                                                                        #"
   echo "#       ______         _   _           _____          _                  #"
   echo "#       | ___ \       | | | |         |_   _|        | |                 #"
   echo "#       | |_/ / __ ___| |_| |_ _   _    | | _ __   __| | _____  __       #"
   echo "#       |  __/ '__/ _ \ __| __| | | |   | || '_ \ / _  |/ _ \ \/ /       #"
   echo "#       | |  | | |  __/ |_| |_| |_| |  _| || | | | (_| |  __/>  <        #"
   echo "#       \_|  |_|  \___|\__|\__|\__, |  \___/_| |_|\__,_|\___/_/\_\       #"
   echo "#                               __/ |                                    #"
   echo "#                              |___/                                     #"
   echo "#                                                                        #"
   echo "=========================================================================="
   echo "#                                                                        #"
   echo "#   Hey there!                                                           #"
   echo "#   I missed you a lot.                                                  #"
   echo "#                                                                        #"
   echo "#   This is a formal message which you have encountered a few seconds    #"
   echo "#   back. This is me, $(a2pi_whoami). I'm [$(a2pi_version)] years old. I was born    #"
   echo "#   to make the indexing pretty for your Apache directories. That's      #"
   echo "#   why I'm here for you.                                                #"
   echo "#   I need some permissions on your behalf to let this happen.           #"
   echo "#   I will drop you a message if there's any.                            #"
   echo "#                                                                        #"
   echo "#   Thanks,                                                              #"
   echo "#   $(a2pi_whoami)                                                          #"
   echo "#   An Unofficial Extended Apache2 AutoIndex Module                      #"
   echo "#                                                                        #"
   echo "=========================================================================="
   echo

   if ! a2pi_has apache2; then
      a2pi_err "Apache2 not found"
      a2pi_log "Install Apache2 first using: [apt-get install apache2]"
      a2pi_bye
      exit 1
   fi

   if [ "$(a2pi_euid)" != 0 ]; then
      a2pi_log "I want root access."
      a2pi_log "Please run this script as [sudo] mode"
      a2pi_bye
      exit 1
   fi


   if [ -z "${METHOD}" ]; then
      # Autodetect install method
      if a2pi_has "git"; then
         install_a2pi_from_git
      elif a2pi_has "a2pi_download"; then
         if a2pi_has "tar"; then
            install_a2pi_using "tar"
         elif a2pi_has "unzip"; then
            install_a2pi_using "zip"
         else
            a2pi_err 'You need tar, unzip to extract $(a2pi_whoami)'
            a2pi_bye
            exit 1
         fi
      else
         a2pi_err 'You need git, curl, or wget to install $(a2pi_whoami)'
         a2pi_bye
         exit 1
      fi
   elif [ "${METHOD}" = 'git' ]; then
      if ! a2pi_has git; then
         a2pi_err "You need git to install $(a2pi_whoami)"
         a2pi_bye
         exit 1
      fi
      install_a2pi_from_git
   elif [ "${METHOD}" = 'tar' ] || [ "${METHOD}" = 'targz' ]; then
      if ! a2pi_has "tar"; then
         a2pi_err "You need tar to extract $(a2pi_whoami).tar.gz"
         a2pi_bye
         exit 1
      fi
      if ! a2pi_has "a2pi_download"; then
         a2pi_err "You need curl or wget to install $(a2pi_whoami)"
         a2pi_bye
         exit 1
      fi
      install_a2pi_using "tar"
   elif [ "${METHOD}" = 'zip' ]; then
      if ! a2pi_has "unzip"; then
         a2pi_err "You need zip to extract $(a2pi_whoami).zip"
         a2pi_bye
         exit 1
      fi
      if ! a2pi_has "a2pi_download"; then
         a2pi_err "You need curl or wget to install $(a2pi_whoami)"
         a2pi_bye
         exit 1
      fi
      install_a2pi_using "zip"
   else
      a2pi_err "The environment variable \$METHOD is set to \"${METHOD}\", which is not recognized as a valid installation method."
      exit 1
   fi

   echo

   if ! a2pi_exec mv -f "$(a2pi_install_dir)/prettyindex."* "/etc/apache2/mods-available/"; then
      a2pi_err "Sorry, Launch Failed. Please report, so that pilot take care of it."
   else
      a2pi_log "Data Loaded, your machine is ready for the flight."
      a2pi_log "Let us configure modules."
      echo
      a2pi_exec a2dismod autoindex -f && a2pi_log "AutoIndex has been disabled" || a2pi_err "Failed to disable AutoIndex"
      a2pi_exec a2enmod prettyindex -f && a2pi_log "PrettyIndex has been enabled" || a2pi_err "Failed to enable PrettyIndex"
      a2pi_exec service apache2 restart && a2pi_log "Apache2 is now restarted" || a2pi_err "Failed to restart Apache2"
      echo
      a2pi_log "Congratulations, we succeeded..!"
   fi

   a2pi_bye
   a2pi_reset
   exit
}

#
# Unsets the various functions defined
# during the execution of the install script
#
a2pi_reset() {
   unset -f a2pi_whoami a2pi_version a2pi_has a2pi_euid a2pi_exec a2pi_install_dir \
            a2pi_source a2pi_download install_a2pi_from_git install_a2pi_using \
            a2pi_do_install a2pi_reset a2pi_log a2pi_err a2pi_bye
}


METHOD="targz" && a2pi_do_install

} # this ensures the entire script is downloaded #