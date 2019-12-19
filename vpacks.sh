#!/usr/bin/env bash

__vpacks_completions()
{
	if [ -d $HOME/.vim ]; then
		local vimdir=$HOME/.vim
	elif [ -d $HOME/vimfiles]; then
		local vimdir=$HOME/vimfiles
	else
		return
	fi
	if [ "${#COMP_WORDS[@]}" == "2" ]; then
		COMPREPLY=($(compgen -W "list update status verbose web git exe log move2opt move2start remotes fetch graph helptags restore backup terminal install" "${COMP_WORDS[1]}"))
	elif [ "${#COMP_WORDS[@]}" == "3" ]; then
		if [ "${COMP_WORDS[1]}" == "restore" ]; then
			local backups=$(echo $vimdir/pack/backup/* | sed "s@$vimdir/pack/backup/@@g")
			COMPREPLY=($(compgen -W "$backups" "${COMP_WORDS[2]}"))
		else
			local packdirs=$(echo $vimdir/pack/* | sed "s@$vimdir/pack/@@g")
			local packs=$(echo $vimdir/pack/*/*/* | sed "s@$vimdir/pack/[^/]\+/[^/]\+/@@g")
			COMPREPLY=($(compgen -W "$packdirs $packs" "${COMP_WORDS[2]}"))
		fi
	else
		return
	fi
}

complete -F __vpacks_completions vpacks

