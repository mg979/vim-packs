#!/usr/bin/env bash

# in Windows, replace .vim with vimfiles!

__vpacks_completions()
{
	if [ "${#COMP_WORDS[@]}" == "2" ]; then
		COMPREPLY=($(compgen -W "list update status verbose fetch move2start move2opt install remotes git" "${COMP_WORDS[1]}"))
	elif [ "${#COMP_WORDS[@]}" == "3" ]; then
		local packdirs=$(echo $HOME/.vim/pack/* | sed "s@$HOME/.vim/pack/@@g")
		local packs=$(echo $HOME/.vim/pack/*/*/* | sed "s@$HOME/.vim/pack/[^/]\+/[^/]\+/@@g")
		COMPREPLY=($(compgen -W "$packdirs $packs" "${COMP_WORDS[2]}"))
	else
		return
	fi
}

complete -F __vpacks_completions vpacks

