#!/bin/zsh -f
# Purpose: reset Dropbox permissions as per to https://www.dropbox.com/en/help/72
#
# From:	Tj Luo.ma
# Mail:	luomat at gmail dot com
# Web: 	http://RhymesWithDiploma.com
# Date:	2014-09-30

DROPBOX_DIR="$HOME/Dropbox"
DROPBOX_CONFIG="$HOME/.dropbox"
DROPBOX_MASTER="$HOME/.dropbox-master"



##########################################################################################


NAME="$0:t:r"

zmodload zsh/datetime

TIME=$(strftime "%Y-%m-%d-at-%H.%M.%S" "$EPOCHSECONDS")

HOST=`hostname -s`
HOST="$HOST:l"

LOG="$HOME/Library/Logs/$NAME.$TIME.txt"

[[ -d "$LOG:h" ]] || mkdir -p "$LOG:h"
[[ -e "$LOG" ]] || touch "$LOG"

function timestamp { strftime "%Y-%m-%d at %H:%M:%S" "$EPOCHSECONDS" }
function log { echo "$NAME [`timestamp`]: $@" | tee -a "$LOG" }



PID=`pgrep -x Dropbox`

if [ "$PID" != "" ]
then
	MSG="Dropbox is running ($PID)."

	if (( $+commands[growlnotify] ))
	then
		pgrep -q -x Growl && \
		growlnotify --appIcon "Dropbox" --identifier "$NAME" --message "$MSG" --title "$NAME"
	fi

	log "$MSG"

	if (( $+commands[quit] ))
	then
		read "?Quit Dropbox? [Y/n]: " ANSWER

		case "$ANSWER" in
		N*|n*)
			log "Ok, not quitting Dropbox"
			exit 0
		;;

		esac

		quit Dropbox
	else
		exit 0
	fi
fi

pgrep -x -q Dropbox && log "Dropbox is still running" && exit 0

echo "\n\n\t$NAME: About to fix Dropbox permissions. \n\tPlease enter your account password if prompted.\n" | tee -a "$LOG"

sudo -v

log "Starting at `timestamp`..."

if [ -e "${DROPBOX_MASTER}" ]
then

	sudo chflags -R nouchg "${DROPBOX_DIR}" "${DROPBOX_DIR}" "${DROPBOX_MASTER}" 2>&1 | tee -a "$LOG" && \
	log "Finished step 1/5" && \
		sudo chown "$USER" "$HOME" 2>&1 | tee -a "$LOG" && \
		log "Finished step 2/5" && \
			sudo chown -R "$USER" "${DROPBOX_DIR}" "${DROPBOX_DIR}" "${DROPBOX_MASTER}" 2>&1 | tee -a "$LOG" && \
			log "Finished step 3/5" && \
				sudo chmod -RN "${DROPBOX_DIR}" "${DROPBOX_DIR}" "${DROPBOX_MASTER}" 2>&1 | tee -a "$LOG" && \
				log "Finished step 4/5" && \
					chmod -R u+rw "${DROPBOX_DIR}" "${DROPBOX_DIR}" "${DROPBOX_MASTER}" 2>&1 | tee -a "$LOG"
					log "Finished step 5/5"
else

		# The .dropbox-master file/folder does not exist on any of my Macs.

	log "${DROPBOX_MASTER} does not exist."

	sudo chflags -R nouchg "${DROPBOX_DIR}" "${DROPBOX_DIR}" 2>&1 | tee -a "$LOG" && \
	log "Finished step 1/5" && \
		sudo chown "$USER" "$HOME" 2>&1 | tee -a "$LOG" && \
		log "Finished step 2/5" && \
			sudo chown -R "$USER" "${DROPBOX_DIR}" "${DROPBOX_DIR}" 2>&1 | tee -a "$LOG" && \
			log "Finished step 3/5" && \
				sudo chmod -RN "${DROPBOX_DIR}" "${DROPBOX_DIR}" 2>&1 | tee -a "$LOG" && \
				log "Finished step 4/5" && \
					chmod -R u+rw "${DROPBOX_DIR}" "${DROPBOX_DIR}" 2>&1 | tee -a "$LOG"
					log "Finished step 5/5"
fi

if [[ "$?" == "0" ]]
then
	log "Fixed permissions. Now launching Dropbox..."
	open --hide --background -a "Dropbox"
else
	log "Permission fix failed"
	exit 1
fi

exit
#
#EOF
