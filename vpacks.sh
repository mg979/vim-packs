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
		COMPREPLY=($(compgen -W "list update dirty lastdiff verbose web git exe log logs move2opt move2start remotes fetch graph helptags restore backup terminal install" "${COMP_WORDS[1]}"))
	elif [ "${#COMP_WORDS[@]}" == "3" ]; then
		if [ "${COMP_WORDS[1]}" == "restore" ]; then
			local backups=$(printf "%s\n" $vimdir/pack/backup/* | sed "s@$vimdir/pack/backup/@@g")
			COMPREPLY=($(compgen -W "$backups" "${COMP_WORDS[2]}"))
		elif [ "${COMP_WORDS[1]}" == "logs" ]; then
			local packdirs=$(printf "%s\n" $vimdir/pack/* | grep -Ev 'backups|logs' | sed "s@$vimdir/pack/@@g")
			local packs=$(printf "%s\n" $vimdir/pack/*/*/* | grep -E 'start|opt' | sed "s@$vimdir/pack/[^/]\+/[^/]\+/@@g")
			COMPREPLY=($(compgen -W "errors clear clearall rm $packdirs $packs" "${COMP_WORDS[2]}"))
		else
			local packdirs=$(printf "%s\n" $vimdir/pack/* | grep -Ev 'backups|logs' | sed "s@$vimdir/pack/@@g")
			local packs=$(printf "%s\n" $vimdir/pack/*/*/* | grep -E 'start|opt' | sed "s@$vimdir/pack/[^/]\+/[^/]\+/@@g")
			COMPREPLY=($(compgen -W "$packdirs $packs" "${COMP_WORDS[2]}"))
		fi
	else
		return
	fi
}

complete -F __vpacks_completions vpacks

