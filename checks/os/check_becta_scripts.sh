#=============================================================================
#
# check_snltd_scripts.sh
# ----------------------
#
# Look for new messages in the snltd_scripts.log file. Zone-aware
#
# R Fisher 02/2009
#
# v1.0  Initial Release
#
# v2.0  Rewritten to use new log_checker() function. RDF 26/02/09
#
#=============================================================================

#-----------------------------------------------------------------------------
# VARIABLES

DATE_MATCH=$(date "+%b %e")
	# Syslog lines begin with a date in this format

SEV_MATCH="emerg\]|alert\]|crit\]|error\]|warning\]" 
	# Another regex. We only care about log files with these lines

LOGFILE="var/log/snltd_scripts.log"

EXIT=10

#-----------------------------------------------------------------------------
# SCRIPT STARTS HERE

for zone in $ZONE_LIST
do
	FPATH="$(get_zone_root_dir $zone)/$LOGFILE"

	if [[ -f $FPATH ]]
	then
		BLOCK=$(log_checker $FPATH "$DATE_MATCH" "$SEV_MATCH")

		if [[ -n $BLOCK ]]
		then

			# We flag a warning if the only lines contain "warning".
			# Otherwise, it's an error

			egrep -sv "warning]" $BLOCK \
				&& ERRORS=1 \
				|| WARNINGS=1
		
			if [[ -n $RUN_DIAG ]]
			then
				print "in zone '$zone':\n"
				cat $BLOCK
			fi
	
		fi
	
	else
		
		# The global zone should have a snltd_scripts log, local zones
		# probably don't. So we don't care if there's nothing in a local
		# zone.

		if [[ $zone == global ]]
		then
			ERRORS=1

			[[ -n $RUN_DIAG ]] && \
				print "zone '$zone' does not have a snltd_scripts.log file."
		fi

	fi

done

if [[ -n $ERRORS ]]
then
	EXIT=2
elif [[ -n $WARNINGS ]]
then
	EXIT=1
fi

exit $EXIT

