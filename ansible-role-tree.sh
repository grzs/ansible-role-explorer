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
indent_str="|     "

# function definition
function walk {
    cwd="${route[-1]}"
    tasks_file="${cwd}/${1}"

    # read file
    IFS=$'\n' lines=($(cat "${tasks_file}" | sed -e 's/^[[:space:]]*//'))
    for l in ${lines[@]}; do
	case $l in
	    -\ name:*)
		let "count++"
		printf "\n%s%03d %s" "$indent" "$count" "${l}"
		;;
	    block:*)
		printf "\n%s%s" "${indent}${indent_str}" "${1}"
		;;
	    when:x*)
		printf "\n%s%s" "${indent}${indent_str}" "$1"
		printf "\n%s" "${indent}${indent_str}"
		;;
	    include_tasks:*)
		included=$(echo $l | awk '{print $2}')

		filename=`basename ${included}`
		subdir=`dirname ${included}`
		if [[ $subdir != "." ]]; then
		    cwd="${route[-1]}/${subdir}"
		fi
		# append cwd to route
		route=( ${route[@]} ${cwd} )

		printf "\n%s%s" "${indent}" "${indent_str}${indent_str}"
		#printf "\n%s%s%s %s" "${indent}" "${indent_str}" "include_tasks:" "${cwd}/${filename}"

		indent="${indent}${indent_str}"
		walk ${filename}
		indent="${indent:: -${#indent_str}}"
		;;
	    *)
		#echo $l
		;;
	esac
    done

    # pop last item
    unset 'route[${#route[@]}-1]'
    printf "\n%s%s\n%s" "$indent" "<<" "$indent"
}

cd $1
role=`basename ${PWD}`
echo -e "Tasks in role ${role}:\n"

walk ${start}

exit 0
