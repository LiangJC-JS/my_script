#!/bin/bash

BRANCH=`git branch | grep "*" | cut -d "*" -f2`
LINUX54=main
LINUX510=linux-5.10.y

sync_linux_54 ()
{
	git pull `cat flippy.txt | sed -n "/5.4/p"`
	git push origin $LINUX54
	git switch $LINUX510
	git pull `cat flippy.txt | sed -n "/5.10/p"`
	git push origin $LINUX510

}

sync_linux_510 ()
{
	git pull `cat flippy.txt | sed -n "/5.10/p"`
	git push origin $LINUX510
	git switch $LINUX54
	git pull `cat flippy.txt | sed -n "/5.4/p"`
	git push origin $LINUX54
}

if [ $BRANCH == "$LINUX54" ];then
	sync_linux_54 
elif [ $BRANCH == "$LINUX510" ];then
	sync_linux_510 
else
	echo "未知版本，目前仅支持5.4，5.10"
	exit 3
fi	
