#!/bin/bash

cwd="tasks"
start="main.yml"
if [[ ! -f "${1}/${cwd}/${start}" ]]; then
    echo "not found ${1}/${cwd}/${start}"
    exit 1
fi

# initial values for function
count=0
route=( "${cwd}" )
indent=""
indent_str="|  "

# function definition
function walk {
    cwd="${route[@]: -1}"
    tasks_file="${cwd}/${1}"
    echo -n $indent
    echo $tasks_file
    IFS=$'\n' lines=($(cat "${tasks_file}" | sed -e 's/^[[:space:]]*//'))
    for l in ${lines[*]}; do
	pattern='(- name:)|(include_tasks:)|(block:)|(when:)|-'
	case $l in
	    -\ name:*)
		let "count++"
		echo -n $indent
		echo "${count} ${l}"
		;;
	    include_tasks:*)
		included=$(echo $l | awk '{print $2}')
		echo -n "${indent}${indent_str}"
		echo -e "${l}"
		echo "${indent}${indent_str}${indent_str}"

		filename=`basename ${included}`
		subdir=`dirname ${included}`
		if [[ $subdir != "." ]]; then
		    cwd="${cwd}/${subdir}"
		fi
		# append cwd to route
		route=( ${route[@]} ${cwd} )

		indent="${indent}${indent_str}"
		walk ${filename}
		indent="${indent:: -${#indent_str}}"
		#echo -n $indent
		#echo "resume to ${route[@]}"
		;;
	esac
    done

    # pop last item
    unset 'route[${#route[@]}-1]'
    echo -n $indent
    echo -e "EOF"
    echo $indent
}

cd $1
role=`basename ${PWD}`
echo -e "Tasks in role ${role}:\n"

walk ${start}

exit 0
