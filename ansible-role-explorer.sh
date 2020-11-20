#!/bin/bash

root="tasks"
start="main.yml"
if [[ ! -f "${1}/${root}/${start}" ]]; then
    echo "not found ${1}/${root}/${start}"
    exit 1
fi

# initial values for function
steps=0
route=()
indent=""
indent_str="|     "

# function definition
function walk {
    echo "${indent}>> ${1}"

    # append path to route
    route=( ${route[@]} ${1} )

    # entering the file at head of route
    IFS=$'\n' lines=($(cat "${route[-1]}" | sed -e 's/^[[:space:]]*//'))

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
		echo -n "${indent}${indent_str}"
		echo -e "include_tasks:"
		echo "${indent}${indent_str}${indent_str}"

		# check if relative include and set parent dir
		[[ ${#route[@]} > 0 ]] && parent_dir=`dirname ${route[-1]}` || parent_dir="${root}"
		[[ -f "${parent_dir}/${included}" ]] || parent_dir="${root}"

		# dive into included
		indent="${indent}${indent_str}"
		walk "${parent_dir}/${included}"
		indent="${indent:: -${#indent_str}}"
		# resume from included
		;;
	    *)
		#echo $l
		;;
	esac
    done
    # reached EOF
    # pop path from route
    unset 'route[${#route[@]}-1]'
    if [[ ${#route[@]} > 0 ]]; then
	echo "${indent}"
	echo "${indent::-6}<< ${route[-1]}"
    fi
}

cd $1
role=`basename ${PWD}`
echo -e "Tasks in role ${role}:\n"

walk "${root}/${start}"

exit 0
