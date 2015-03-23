#!/bin/bash

# This script is used within containers to turn it into a Mail-in-a-Box.
# It is referenced by the Dockerfile. You should not run it directly.
########################################################################

# Local configuration details were not known at the time the Docker
# image was created, so all setup is defered until the container
# is started. That's when this script runs.

# If we're not in an interactive shell, set defaults.
if [ ! -t 0 ]; then
	echo '*** Non interactive shell detected...'
	export PUBLIC_IP=`[ -z ${PUBLIC_IP} ] && echo "auto" || echo $PUBLIC_IP`
	export PUBLIC_IPV6=`[ -z ${PUBLIC_IPV6} ] && echo "auto" || echo $PUBLIC_IPV6`
	export PRIMARY_HOSTNAME=`[ -z ${PRIMARY_HOSTNAME} ] && echo "auto" || echo $PRIMARY_HOSTNAME`
	export CSR_COUNTRY=`[ -z ${CSR_COUNTRY} ] && echo "US" || echo $CSR_COUNTRY`
	export NONINTERACTIVE=`[ -z ${NONINTERACTIVE} ] && echo "1" || echo $NONINTERACTIVE`
fi

if ([ -z "$FORCE_INSTALL" ] && [ -f /var/lib/mailinabox/api.key ]); then
	# Mailinabox is already installed and we don't want to reinstall
	export SKIP_INSTALL=1
fi

# If we are skipping install, reload from /etc/mailinabox.conf if exists
if ([ -f /var/lib/mailinabox/api.key ] && [ ! -z "$SKIP_INSTALL" ]); then
	echo '*** Loading variables from "/etc/mailinabox.conf"...'

	source /etc/mailinabox.conf
	unset PRIVATE_IP
	unset PRIVATE_IPV6
	export SKIP_NETWORK_CHECKS=1
	export NONINTERACTIVE=1
fi

# Start configuration. Using 'source' means an exit from inside
# also exits this script and terminates the container.
export DISABLE_FIREWALL=1

cd /usr/local/mailinabox

if [ -z "$SKIP_INSTALL" ]; then
	# Disable all services.
	/usr/local/mailinabox/containers/docker/tools/disable_services.sh

	echo "*** Starting mailinabox installation..."
	# Run in background to avoid blocking runit initialization while installing.
	source setup/start.sh &
else
	echo "*** Configuring mailinabox..."
	# Run in foreground for services to be started after configuration.
	source setup/configure.sh
fi
