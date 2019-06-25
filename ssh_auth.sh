#!/bin/bash

if test $# -lt 3
then
    echo "usage: $0 <host> <user> <passwd>"
    echo "return: 0 - ok; 1 - bad passwd; other - unreachable, timeout etc"
    exit 2
fi

host=$1
user=$2
passwd=$3
key=~/.ssh/id_rsa

exec >/dev/null

ssh-keygen -f ~/.ssh/known_hosts -R $host >/dev/null 2>&1

# test first
expect << EOF
set timeout 30

spawn ssh $user@$host true
expect {
	"(yes/no)?" { exit 1 }
	"*'s password:" { exit 1 }
	"No route to host" { exit 2 }
	"Permission denied" { exit 1 }
	eof { 
		catch wait result
		exit [lrange \$result 3 3]
	}
}
EOF

ret=$?
test $ret = 0 && exit 0
test $ret = 2 && exit 2

if [ ! -r $key ]; then
	ssh-keygen -q -f $key -N '' -t rsa
fi

expect << EOF
set timeout 30

spawn ssh-copy-id -i $key.pub $user@$host 
expect {
	"(yes/no)?" { exp_send "yes\n" ; exp_continue }
	"Permission denied" { exit 1 }
	"*'s password:" { exp_send "$passwd\n" ; exp_continue }
	"No route to host" { exit 2 }
	eof { 
		catch wait result
		exit [lrange \$result 3 3]
	}
}
EOF

