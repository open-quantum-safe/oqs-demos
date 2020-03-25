#!/bin/bash

set -e 

# Detects whether there has been a Git commit in the last day on this
# branch. Returns 1 if there has been a commit, 0 if there has not.

r=$(git log --name-only --since="1 second ago" -n 2)
if [ "x$r" == "x" ]; then 
    echo "No oqs-demos commit in the last day. Checking liboqs now."
    if [ -d tmp/liboqs ]; then
            cd tmp/liboqs
            r=$(git log --name-only --since="1 day ago" -n 2)
            if [ "x$r" == "x" ]; then 
                echo "Also no liboqs commit in the last day. Now checking openssl."
                if [ -d ../tmp/openssl ]; then
            		cd ../tmp/openssl
            		r=$(git log --name-only --since="1 day ago" -n 2)
            		if [ "x$r" == "x" ]; then 
                		echo "Also no openssl commit in the last day. Build not necessary."
                		exit 0
            		else
               			echo "openssl commit found. Should test."
                		exit 1
            		fi
	
    		else
       			echo "Shouldn't happen (openssl not checked out?). Testing recommended."
        		exit 1
    		fi
            else
                echo "liboqs commit found. Should test."
                exit 1
            fi
    else
        echo "Shouldn't happen (liboqs not checked out?). Testing recommended."
        exit 1
    fi
else
    exit 1
fi
