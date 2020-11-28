#!/bin/bash

root="tasks"
start="main.yml"
if [[ ! -f "${1}/${root}/${start}" ]]; then
    echo "not found ${1}/${root}/${start}"
    exit 1
fi

# initial values for functions
steps=0
route=()
tab=4
level=0
task_prefix=""

# function definitions
function indenter {
    echo
    i=0; while [[ i -ne $level ]]; do
	printf "|%${tab}s"
	let i++
    done
}

function walk {
    indenter
    printf "[%s]" "${1}"

    # append path to route
    route=( ${route[@]} ${1} )

    # entering the file at head of route
    IFS=$'\n' lines=($(cat "${route[-1]}" | sed -e 's/^[[:space:]]*//'))

    # iterate over lines
    for l in ${lines[@]}; do
	case $l in
	    -\ name:*)
		if [[ $task_cur ]]; then
		    indenter
		    printf "%s %s" "$task_prefix" "${task_cur}"
		    if [[ $when ]]; then
			printf " -- ??%s" "${when:5}"
			unset when
		    fi
		fi
		let steps++
		task_prefix=`printf "%03d" ${steps}`
		task_cur=$(echo $l | sed 's/^- name: //')
		;;
	    set_fact:*)
		task_prefix+=" (set_fact)"
		;;
	    block:*)
		let steps--
		task_prefix="  { block start -"
		;;
	    rescue:*)
		let steps--
		task_prefix="  } rescue :"
		;;
	    when:*)
		when=$l
		;;
	    -\ *)
		if [[ $when =~ ^when:.* ]]; then
		    when+="${l:1} ??"
		fi
		;;
	    include_tasks*|import_tasks*)
		included=$(echo $l | awk '{print $2}')
		let steps--
		task_prefix="include_tasks"
		
		indenter
		printf "|\_"
		indenter
		printf "|  \_ %s - %s" "${task_prefix}" "${task_cur}"
		unset task_cur

		# check if relative include and set parent dir
		parent_dir=`dirname ${route[-1]}`
		[[ -f "${parent_dir}/${included}" ]] || parent_dir="${root}"

		# dive into included
		let "level++"
		walk "${parent_dir}/${included}"
		# resume from included
		;;
	    *)
		#echo $l
		;;
	esac
    done
    # reached EOF
    # print last task
    if [[ $task_cur ]]; then
	indenter
	printf "%s %s" "$task_prefix" "${task_cur}"
    fi
	unset task_cur

    # pop path from route
    unset 'route[${#route[@]}-1]'
    if [[ ${#route[@]} > 0 ]]; then
	indenter
	let "level--"
	indenter
	printf "[%s]" "${route[-1]}"
    fi
}

cd $1
role=`basename ${PWD}`
echo -e "Tasks in role ${role}:"

walk "${root}/${start}"

exit 0
