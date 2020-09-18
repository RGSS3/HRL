#!/usr/bin/env bash

if [ r`which sudo` != r"" ];
then
	sudox() {
		sudo $*
	}
else
	sudox() {
		$*
	}
fi

if [ r"$HOME" != r"" ];
then
	homepath=$HOME
else
	homepath=/root
fi

write_file () {
    name=`mktemp hrlXXXXX`
	cat $2 > $name
	sudox cp $name $1
	rm $name
}

sudox sed -i "s/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list
sudox apt update -y
echo -e "6\n70\n" | sudox apt install -y tzdata
sudox apt install -y g++-10 gcc-10 clang-tidy astyle cppcheck valgrind python3 python3-pip watchdog openssh-server micro
sudox pip3 install cpplint -i https://pypi.tuna.tsinghua.edu.cn/simple
sudox sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes" /etc/ssh/sshd_config

sudox systemctl enable watchdog
sudox systemctl start watchdog
sudox systemctl restart sshd

write_file "/usr/local/bin/hrl-run" <<'EOF'
#!/usr/bin/env bash
export args="-Wall -Werror -Wextra -pedantic -Wimplicit-fallthrough -Wsequence-point -Wswitch-default -Wswitch-unreachable -Wswitch-enum -Wstringop-truncation -Wbool-compare -Wtautological-compare -Wfloat-equal -Wshadow=global -Wpointer-arith -Wpointer-compare -Wcast-align -Wcast-qual -Wwrite-strings -Wdangling-else -Wlogical-op -Wconversion -g"
export args2="-Wall -Werror -Wextra -pedantic -Wimplicit-fallthrough -Wsequence-point -Wswitch-default -Wswitch-enum -Wtautological-compare -Wfloat-equal -Wpointer-arith -Wcast-align -Wcast-qual -Wwrite-strings -Wdangling-else -Wconversion -Wunused-result"

python3 -m cpplint "--filter=-legal/copyright,+*" --quiet $1 && \
cppcheck -q --enable=warning --enable=style --enable=performance --enable=portability --error-exitcode=1 $1 &&   \
gcc $* -c $args -o a.o && \
#oclint $* -- gcc $* -c $args2 -o a.o  && \
clang-tidy --config="---
Checks:          '*, -modernize-use-trailing-return-type, -clang-analyzer-security.insecureAPI.DeprecatedOrUnsafeBufferHandling'
WarningsAsErrors: '*'
HeaderFilterRegex: ''
AnalyzeTemporaryDtors: false
FormatStyle:     none
User:            mini
CheckOptions:
  - key:             cert-dcl16-c.NewSuffixes
    value:           'L;LL;LU;LLU'
  - key:             cert-oop54-cpp.WarnOnlyIfThisHasSuspiciousField
    value:           '0'
  - key:             cppcoreguidelines-explicit-virtual-functions.IgnoreDestructors
    value:           '1'
  - key:             cppcoreguidelines-non-private-member-variables-in-classes.IgnoreClassesWithAllMemberVariablesBeingPublic
    value:           '1'
  - key:             google-readability-braces-around-statements.ShortStatementLines
    value:           '1'
  - key:             google-readability-function-size.StatementThreshold
    value:           '20'
  - key:             google-readability-namespace-comments.ShortNamespaceLines
    value:           '10'
  - key:             google-readability-namespace-comments.SpacesBeforeComments
    value:           '2'
  - key:             modernize-loop-convert.MaxCopySize
    value:           '16'
  - key:             modernize-loop-convert.MinConfidence
    value:           reasonable
  - key:             modernize-loop-convert.NamingStyle
    value:           CamelCase
  - key:             modernize-pass-by-value.IncludeStyle
    value:           llvm
  - key:             modernize-replace-auto-ptr.IncludeStyle
    value:           llvm
  - key:             modernize-use-nullptr.NullMacros
    value:           'NULL'
...
" --fix --fix-errors --quiet $* -- $args2 && \
gcc a.o -o a.out && \
valgrind -q --leak-check=full --show-leak-kinds=all ./a.out
EOF

sudox chmod +x /usr/local/bin/hrl-run

write_file "/usr/local/bin/hrl-edit" <<'EOF'
export SHELL=bash
export TERM=xterm-256color
micro $*
EOF

sudox chmod +x /usr/local/bin/hrl-edit
