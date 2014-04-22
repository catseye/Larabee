#!/bin/sh

# basically just a sanity test

if [ -z $SCHEME_IMPL ]; then
    SCHEME_IMPL='csi -q'
fi

cd src
cat >test-input.txt <<EOF
(test2)
4
9
EOF
cat >expected-output.txt <<EOF
13
OK

EOF
$SCHEME_IMPL test.scm < test-input.txt > test-output.txt || exit 1
diff -u expected-output.txt test-output.txt
RESULT=$?
rm -f test-input.txt expected-output.txt test-output.txt
exit $RESULT
