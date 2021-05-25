function applyFile() {
	path=$1
	dc=$2
	connectionString=$3
	if [[ "${dc}" == "dc3" ]]; then
		logCount=0
	else
		logCount=-1
	fi
	
  sed -e "s/\$dc/$dc/" "${path}" | sed -e "s/\$logCount/$logCount/" | sed -e "s/\$connectionString/$connectionString/" | kubectl apply -f -
}

function checkReconciliation() {
	clusterName=$1

	generationsOutput=$(kubectl get fdb "${clusterName}" -o jsonpath='{.metadata.generation} {.status.generations.reconciled}')
	read -ra generations <<< "${generationsOutput}"
	if [[ ("${generations[1]}" != "")  && ("${generations[0]}" == "${generations[1]}") ]]; then
		return 1
	else
		echo "Latest generations for $clusterName: $generationsOutput"
		return 0
	fi
}

function getConnectionString() {
	clusterName=$1

	kubectl get fdb "${clusterName}" -o jsonpath='{.status.connectionString}'
}

function checkReconciliationLoop() {
	reconciled=0
	name=$1
	while [ $reconciled -ne 1 ] ; do
		checkReconciliation "${name}"
		reconciled=$?
		if [[ $reconciled -ne 1 ]]; then
			echo "Waiting for reconciliation"
			sleep 5
		fi
	done
}
