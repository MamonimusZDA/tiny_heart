#! /usr/bin/env awk -f

BEGIN {
  ORS = "";

  oid  = ""
  head = "";

  ahead  = 0;
  behind = 0;

  untracked = 0;
  unmerged  = 0;

  staged   = 0;
  unstaged = 0;

  stashed = 0;
}

$2 == "branch.oid" {
  oid = $3;
}

$2 == "branch.head" {
  head = $3;
}

$2 == "branch.ab" {
  behind = $4;
  ahead = $3;
}

$1 == "?" {
  ++untracked;
}

$1 == "u" {
  ++unmerged;
}

$1 == "1" || $1 == "2" {
  split($2, arr, "");
  if (arr[1] != ".") {
    ++staged;
  }
  if (arr[2] != ".") {
    ++unstaged;
  }
}

$2 == "stash.count" {
  stashed = $3;
}

END {
  printf "%%F{%s}", COLOR_INFO;
  if (!(head == "(detached)")) {
    gsub("%", "%%", head);
    print head;
  } else {
    print substr(oid, 0, 7);
  } print RC;

  if (behind < 0) {
    printf " %%F{%s}%s%d%s",
           COLOR_BEHIND,
           BEHIND_ICON,
           behind * -1, RC;
  }

  if (ahead > 0) {
    printf " %%F{%s}%s%d%s",
           COLOR_AHEAD,
           AHEAD_ICON,
           ahead, RC;
  }

  if (untracked > 0) {
    printf " %%F{%s}%s%d%s",
           COLOR_UNTRACKED,
           UNTRACKED_ICON,
           untracked, RC;
  }

  if (unmerged > 0) {
    printf " %%F{%s}%s%d%s",
           COLOR_UNMERGED,
           UNMERGED_ICON,
           unmerged, RC;
  }

  if (staged > 0) {
    printf " %%F{%s}%s%d%s",
           COLOR_STAGED,
           STAGED_ICON,
           staged, RC;
  }

  if (unstaged > 0) {
    printf " %%F{%s}%s%d%s",
           COLOR_UNSTAGED,
           UNSTAGED_ICON,
           unstaged, RC;
  }

  if (stashed > 0) {
    printf " %%F{%s}%s%d%s",
           COLOR_STASHED,
           STASHED_ICON,
           stashed, RC;
  }
}
