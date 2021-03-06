#!/bin/bash

# Usage: ./test.sh [--regold] [test-name] [python-version]
# Example:
#   Run all tests:
#     ./test.sh python3
#   Regold all tests:
#     ./test.sh --regold python3
#   Run one test:
#     ./test.sh tests/gold-45-sas-h-nb.txt python3
#   Regold one test:
#     ./test.sh --regold tests/gold-45-sas-h-nb.txt python3

if [ "$#" -gt 1 -a "$1" = "--regold" ]; then
  REGOLD=true
  shift
else
  REGOLD=false
fi

TEST_NAME=all
if [ "$#" -gt 1 ]; then
  TEST_NAME=$1
  shift
fi

if [ "$#" != 1 ]; then
  echo "Usage: '$0 [--regold] [test-name] python[23]'"
  exit 1
fi

PYTHON="$1"
ICDIFF="./icdiff"

function fail() {
  echo "FAIL"
  exit 1
}

function check_gold() {
  local gold=tests/$1
  shift

  if [ $TEST_NAME != "all" -a $TEST_NAME != $gold ]; then
    return
  fi

  echo "    check_gold $gold matches $@"
  local tmp=/tmp/icdiff.output
  "$PYTHON" "$ICDIFF" "$@" &> $tmp

  if $REGOLD; then
    cat $tmp
    read -p "Is this correct? y/n > " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      mv $tmp $gold
      echo "Regolded $gold."
    else
      echo "Did not regold $gold."
    fi
    return
  fi

  if ! diff $gold $tmp; then
    echo "Got: ($tmp)"
    cat $tmp
    echo "Expected: ($gold)"
    cat $gold
    fail
  fi
}

check_gold gold-recursive.txt       --recursive tests/{a,b} --cols=80
check_gold gold-12.txt              tests/input-{1,2}.txt --cols=80
check_gold gold-3.txt               tests/input-{3,3}.txt
check_gold gold-45.txt              tests/input-{4,5}.txt --cols=80
check_gold gold-45-95.txt           tests/input-{4,5}.txt --cols=95
check_gold gold-45-sas.txt          tests/input-{4,5}.txt --cols=80 --show-all-spaces
check_gold gold-45-h.txt            tests/input-{4,5}.txt --cols=80 --highlight
check_gold gold-45-nb.txt           tests/input-{4,5}.txt --cols=80 --no-bold
check_gold gold-45-sas-h.txt        tests/input-{4,5}.txt --cols=80 --show-all-spaces --highlight
check_gold gold-45-sas-h-nb.txt     tests/input-{4,5}.txt --cols=80 --show-all-spaces --highlight --no-bold
check_gold gold-45-h-nb.txt         tests/input-{4,5}.txt --cols=80 --highlight --no-bold
check_gold gold-45-ln.txt           tests/input-{4,5}.txt --cols=80 --line-numbers
check_gold gold-45-nh.txt           tests/input-{4,5}.txt --cols=80 --no-headers
check_gold gold-45-h3.txt           tests/input-{4,5}.txt --cols=80 --head=3
check_gold gold-45-l.txt            tests/input-{4,5}.txt --cols=80 -L left
check_gold gold-45-lr.txt           tests/input-{4,5}.txt --cols=80 -L left -L right
check_gold gold-67.txt              tests/input-{6,7}.txt --cols=80
check_gold gold-67-wf.txt           tests/input-{6,7}.txt --cols=80 --whole-file
check_gold gold-67-ln.txt           tests/input-{6,7}.txt --cols=80 --line-numbers
check_gold gold-67-u3.txt           tests/input-{6,7}.txt --cols=80 -U 3

if [ $(./icdiff --version | awk '{print $NF}') != $(head -n 1 ChangeLog) ]; then
  echo "Version mismatch between ChangeLog and icdiff source."
  fail
fi

if ! $REGOLD; then
  echo PASS
fi
