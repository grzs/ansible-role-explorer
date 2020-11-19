#!/bin/bash

root="tasks"
start="main.yml"
if [[ ! -f "${1}/${cwd}/${start}" ]]; then
    echo "not found ${1}/${cwd}/${start}"
    exit 1
fi

# initial values for function
steps=0
route=( "${root}" )
indent=""
indent_str="|     "

# function definition
function walk {
    cwd="${route[-1]}"

    # if not relative include, default cwd to route
    [[ -f "${cwd}/${1}" ]] || cwd="${root}"

    # entering the file
    tasks_file="${cwd}/${1}"
    IFS=$'\n' lines=($(cat "${tasks_file}" | sed -e 's/^[[:space:]]*//'))

    # iterate over lines
    for l in ${lines[@]}; do
	case $l in
	    -\ name:*)
		let "steps++"
		printf "%s%03d %s\n" "$indent" "$steps" "${l}"
		;;
	    block:x*)
		echo -n "${indent}${indent_str}"
		echo ${l}
		;;
	    when:x*)
		echo -n "${indent}${indent_str}"
		echo ${l}
		echo "${indent}${indent_str}"
		;;
	    include_tasks:*)
		included=$(echo $l | awk '{print $2}')

		filename=`basename ${included}`
		subdir=`dirname ${included}`

		# push cwd to route
		if [[ $subdir != "." ]]; then
		    cwd="${cwd}/${subdir}"
		fi
		route=( ${route[@]} ${cwd} )

		echo "${indent}${indent_str}${indent_str}"
		echo -n "${indent}${indent_str}"
		echo -e "include_tasks: ${cwd}/${filename}"

		# dive to include
		indent="${indent}${indent_str}"
		walk ${filename}
		indent="${indent:: -${#indent_str}}"
		# resume from include
		;;
	    *)
		#echo $l
		;;
	esac
    done

    # reached EOF
    echo -n $indent
    echo -e "<<"
    echo $indent

    # pop last route item
    unset 'route[${#route[@]}-1]'
}

cd $1
role=`basename ${PWD}`
echo -e "Tasks in role ${role}:\n"

walk ${start}

exit 0
