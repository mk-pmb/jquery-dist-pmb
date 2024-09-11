#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function update_lodash () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m -- "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?

  local WEBSITE_URL='https://lodash.com/'
  local TODAY="$(date +%y%m%d)"
  local WEBSITE_TODAY="tmp.today.$TODAY.html"
  cache-file-wget "$WEBSITE_TODAY" "$WEBSITE_URL" || return $?
  local DL_BASEURL='https://raw.githubusercontent.com/lodash/lodash/'
  local DLL='tmp.download-links.txt'
  grep -oPe '<a [^<>]*>' -- "$WEBSITE_TODAY" | sed -nrf <(echo '
    s~^<a href="?(https:[A-Za-z0-9/.-]+)"?>$~<\1>~p
    ') | tee -- tmp.all_links.txt \
    | grep -Fe "<$DL_BASEURL" >"$DLL"

  local URL="$(grep -Fe '/LICENSE>' -- "$DLL")"
  URL="${URL#'<'}"
  URL="${URL%'>'}"
  [ -n "$URL" ] || return 4$(echo E: 'Failed to detect license URL!' >&2)
  local SAVE="tmp.license.$TODAY.txt"
  cache-file-wget "$SAVE" "$URL" || return $?
  diff -sU 9009009 -- LICENSE.txt "$SAVE" || return $?

  URL="${URL%/*}"
  local RLS_BASEURL="$URL/"
  local RLS_VERSION="${URL##*/}"
  local RLS_FILES=()
  readarray -t RLS_FILES <"$DLL"
  local BFN= LINK= SUF='.min.js'
  for URL in "${RLS_FILES[@]}"; do
    URL="${URL#'<'}"
    URL="${URL%'>'}"
    [ "${URL:0:${#RLS_BASEURL}}" == "$RLS_BASEURL" ] || return 4$(
      echo E: "Download URL '$URL' unexpectedly does not start with" \
        "'$RLS_BASEURL'!" >&2)
    [[ "$URL" == *.min.js ]] || continue
    BFN="${URL:${#RLS_BASEURL}}"
    BFN="${BFN%$SUF}"
    case "$BFN" in
      lodash ) BFN='full';;
    esac
    BFN+='.v'
    SAVE="$BFN$RLS_VERSION$SUF"
    LINK="$BFN${RLS_VERSION%%.*}.x$SUF"
    echo "$LINK = $SAVE <- $URL"
    cache-file-wget "$SAVE" "$URL" || return $?
    [ ! -L "$LINK" ] || rm -- "$LINK" || true
    ln --symbolic --no-target-directory -- "$SAVE" "$LINK" || return $?
  done
}










update_lodash "$@"; exit $?
