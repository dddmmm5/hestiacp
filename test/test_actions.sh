#!/bin/bash

# Define some variables
source /etc/profile.d/hestia.sh
source $HESTIA/conf/hestia.conf

V_BIN="$HESTIA/bin"
V_TEST="$HESTIA/test"

# Define functions
random() {
    MATRIX='0123456789'
    LENGTH=$1
    while [ ${n:=1} -le $LENGTH ]; do
        rand="$rand${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
    done
    echo "$rand"
}

echo_result() {
    echo -en  "$1"
    echo -en '\033[60G'
    echo -n '['

    if [ "$2" -ne 0 ]; then
        echo -n 'FAILED'
        echo -n ']'
        echo -ne '\r\n'
        echo ">>> $4"
        echo ">>> RETURN VALUE $2"
        cat $3
    else
        echo -n '  OK  '
        echo -n ']'
    fi
    echo -ne '\r\n'
}

# Create random username
user="testu-$(random 4)"
while [ ! -z "$(grep "^$[USER]:" /etc/passwd)" ]; do
    user="tmp-$(random 4)"
done

# Create random tmpfile
tmpfile=$(mktemp -p /tmp )
echo $tmpfile >/dev/null 2>&1

# Add release information for test logging details
if [ "$RELEASE_BRANCH" = "release" ]; then
    CERTIFIED_RELEASE_BUILD="Production Release"
fi

if [ "$RELEASE_BRANCH" = "beta" ]; then
    CERTIFIED_RELEASE_BUILD="Pre-Release (Stable)"
fi

if [ "$RELEASE_BRANCH" = "develop" ] || [ "$RELEASE_BRANCH" = "unstable" ] || [ "$RELEASE_BRANCH" = "nightly" ]; then
     CERTIFIED_RELEASE_BUILD="Development (Unstable)"
fi

# Predefine welcome message as function (make more items functions later)
welcome_message() {
    clear
    echo '                _   _           _   _        ____ ____                  '
    echo '               | | | | ___  ___| |_(_) __ _ / ___|  _ \                 '
    echo '               | |_| |/ _ \/ __| __| |/ _` | |   | |_) |                '
    echo '               |  _  |  __/\__ \ |_| | (_| | |___|  __/                 '
    echo '               |_| |_|\___||___/\__|_|\__,_|\____|_|                    '
    echo "                                                                        "
    echo "                   Hestia Control Panel Test Suite                      "
    echo "                            www.hestiacp.com                            "
    echo
    echo "========================================================================"
    echo "Installed software version:   ${VERSION}                                "
    echo "Development branch:           ${RELEASE_BRANCH}                         "
    echo "Build type:                   ${CERTIFIED_RELEASE_BUILD}                "
    echo "========================================================================"
    echo "                                                                        "
    echo "Starting automated validation tests. This will take a few minutes, and  "
    echo "will help assist in detecting issues in the software build that is      "
    echo "currently installed on your server."
    echo ""
    echo "Please wait..."
    echo
}


# Now print the welcome header
welcome_message

###########################################################################################
#
#  USER
#
###########################################################################################

# Add user
cmd="v-add-user $user $user $user@hestiacp.com default Super Test"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Adding new user $user" "$?" "$tmpfile" "$cmd"

# Change user password
cmd="v-change-user-password $user t3st-p4ssw0rd"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Changing password" "$?" "$tmpfile" "$cmd"

# Change user contact
cmd="v-change-user-contact $user tester@hestiacp.com"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Changing email" "$?" "$tmpfile" "$cmd"

# Change system shell
cmd="v-change-user-shell $user bash"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Changing system shell to /bin/bash" "$?" "$tmpfile" "$cmd"

# Change name servers
cmd="v-change-user-ns $user ns0.com ns1.com ns2.com ns3.com"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Changing nameservers" "$?" "$tmpfile" "$cmd"

# Enable Composer
cmd="v-add-user-composer $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Installing Composer" "$?" "$tmpfile" "$cmd"

cmd="v-delete-user-log $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Delete user history log" "$?" "$tmpfile" "$cmd"


echo

###########################################################################################
#
#  CRON
#
###########################################################################################

# Add cron job
cmd="v-add-cron-job $user 1 1 1 1 1 echo"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[CRON]: Adding cron job" "$?" "$tmpfile" "$cmd"

# Suspend cron job
cmd="v-suspend-cron-job $user 1"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[CRON]: Suspending cron job" "$?" "$tmpfile" "$cmd"

# Unsuspend cron job
cmd="v-unsuspend-cron-job $user 1"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[CRON]: Unsuspending cron job" "$?" "$tmpfile" "$cmd"

# Delete cron job
cmd="v-delete-cron-job $user 1"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[CRON]: Deleting cron job" "$?" "$tmpfile" "$cmd"

# Add cron job
cmd="v-add-cron-job $user 1 1 1 1 1 echo 1"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[CRON]: Adding cron job" "$?" "$tmpfile" "$cmd"

# Add cron job
cmd="v-add-cron-job $user 1 1 1 1 1 echo 1"
$cmd > $tmpfile 2>> $tmpfile
if [ "$?" -eq 4 ]; then
    retval=0
else
    retval=1
fi
echo_result "[CRON]: Duplicate cron job check" "$retval" "$tmpfile" "$cmd"

# Add second cron job
cmd="v-add-cron-job $user 2 2 2 2 2 echo 2"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[CRON]: Adding second cron job" "$?" "$tmpfile" "$cmd"

# Rebuild cron jobs
cmd="v-rebuild-cron-jobs $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[CRON]: Rebuilding cron jobs" "$?" "$tmpfile" "$cmd"

echo

###########################################################################################
#
#  IP / NETWORK
#
###########################################################################################

# List network interfaces
cmd="v-list-sys-interfaces plain"
interface=$($cmd 2> $tmpfile | head -n 1)
if [ -z "$interface" ]; then
    echo_result "[IP]: Listing network interfaces" "1" "$tmpfile" "$cmd"
else
    echo_result "[IP]: Listing network interfaces" "0" "$tmpfile" "$cmd"
fi

# Add ip address
cmd="v-add-sys-ip 198.18.0.123 255.255.255.255 $interface $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[IP]: Adding IP 198.18.0.123" "$?" "$tmpfile" "$cmd"

# Add duplicate ip
$cmd > $tmpfile 2>> $tmpfile
if [ "$?" -eq 4 ]; then
    retval=0
else
    retval=1
fi
echo_result "[IP]: Duplicate IP address check" "$retval" "$tmpfile" "$cmd"

# Delete ip address
cmd="v-delete-sys-ip 198.18.0.123"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[IP]: Deleting IP 198.18.0.123" "$?" "$tmpfile" "$cmd"

# Add ip address
cmd="v-add-sys-ip 198.18.0.125 255.255.255.255 $interface $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[IP]: Adding IP 198.18.0.125" "$?" "$tmpfile" "$cmd"

echo

###########################################################################################
#
#  WEB
#
###########################################################################################

# Add web domain
domain="test-$(random 4).hestiacp.com"
cmd="v-add-web-domain $user $domain 198.18.0.125"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Adding domain $domain on 198.18.0.125" "$?" "$tmpfile" "$cmd"

# Add duplicate
$cmd > $tmpfile 2>> $tmpfile
if [ "$?" -eq 4 ]; then
    retval=0
else
    retval=1
fi
echo_result "[WEB]: Duplicate web domain check" "$retval" "$tmpfile" "$cmd"

# Add web domain alias
cmd="v-add-web-domain-alias $user $domain v3.$domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Adding alias v3.$domain" "$?" "$tmpfile" "$cmd"

# Alias duplicate
$cmd > $tmpfile 2>> $tmpfile
if [ "$?" -eq 4 ]; then
    retval=0
else
    retval=1
fi
echo_result "[WEB]: Duplicate web alias check" "$retval" "$tmpfile" "$cmd"

# Add web domain stats
cmd="v-add-web-domain-stats $user $domain awstats"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Enabling awstats" "$?" "$tmpfile" "$cmd"

# Add web domain stats 
cmd="v-add-web-domain-stats-user $user $domain test m3g4p4ssw0rd"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Adding awstats user" "$?" "$tmpfile" "$cmd"

# Suspend web domain
cmd="v-suspend-web-domain $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Suspending web domain" "$?" "$tmpfile" "$cmd"

# Unsuspend web domain
cmd="v-unsuspend-web-domain $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Unsuspending web domain" "$?" "$tmpfile" "$cmd"

# Add web domain ssl
cp -f $HESTIA/ssl/certificate.crt /tmp/$domain.crt
cp -f $HESTIA/ssl/certificate.key /tmp/$domain.key
cmd="v-add-web-domain-ssl $user $domain /tmp"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Enable SSL for web domain" "$?" "$tmpfile" "$cmd"

# Enable HTTPS redirection
cmd="v-add-web-domain-ssl-force $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Enable HTTPS auto direction" "$?" "$tmpfile" "$cmd"

# Disable HTTPS redirection
cmd="v-delete-web-domain-ssl-force $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Disable HTTPS auto direction" "$?" "$tmpfile" "$cmd"

# Enable HSTS
cmd="v-add-web-domain-ssl-hsts $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Enable HTTP Strict Transport Security" "$?" "$tmpfile" "$cmd"

# Disable HSTS
cmd="v-delete-web-domain-ssl-hsts $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Disable HTTP Strict Transport Security" "$?" "$tmpfile" "$cmd"

# Add password protection to web domain
cmd="v-add-web-domain-httpauth $user $domain test-user httpp4ssw0rd"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Enable password protection" "$?" "$tmpfile" "$cmd"

# Remove password protection from web domain
cmd="v-delete-web-domain-httpauth $user $domain test-user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Remove password protection" "$?" "$tmpfile" "$cmd"

# Rebuild web domains
cmd="v-rebuild-web-domains $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[WEB]: Rebuilding web domains" "$?" "$tmpfile" "$cmd"

echo

###########################################################################################
#
#  DNS
#
###########################################################################################

# Add dns domain
cmd="v-add-dns-domain $user $domain 198.18.0.125"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DNS]: Adding DNS domain $domain" "$?" "$tmpfile" "$cmd"

# Add duplicate
$cmd > $tmpfile 2>> $tmpfile
if [ "$?" -eq 4 ]; then
    retval=0
else
    retval=1
fi
echo_result "[DNS]: Duplicate domain check" "$retval" "$tmpfile" "$cmd"

# Add dns record
cmd="v-add-dns-record $user $domain test A 198.18.0.125 20"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DNS]: Adding DNS record" "$?" "$tmpfile" "$cmd"

# Add duplicate
$cmd > $tmpfile 2>> $tmpfile
if [ "$?" -eq 4 ]; then
    retval=0
else
    retval=1
fi
echo_result "[DNS]: Duplicate record check" "$retval" "$tmpfile" "$cmd"

# Delete dns record
cmd="v-delete-dns-record $user $domain 20"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DNS]: Deleting DNS record" "$?" "$tmpfile" "$cmd"

# Change exp
cmd="v-change-dns-domain-exp $user $domain 2020-01-01"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DNS]: Changing expiriation date" "$?" "$tmpfile" "$cmd"

# Change ip
cmd="v-change-dns-domain-ip $user $domain 127.0.0.1"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DNS]: Changing domain IP" "$?" "$tmpfile" "$cmd"

# Suspend dns domain
cmd="v-suspend-dns-domain $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DNS]: Suspending domain" "$?" "$tmpfile" "$cmd"

# Unuspend dns domain
cmd="v-unsuspend-dns-domain $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DNS]: Unsuspending domain" "$?" "$tmpfile" "$cmd"

# Rebuild dns domain
cmd="v-rebuild-dns-domains $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DNS]: Rebuilding domain" "$?" "$tmpfile" "$cmd"

echo 
###########################################################################################
#
#  MAIL
#
###########################################################################################

# Add mail domain
cmd="v-add-mail-domain $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Adding mail domain $domain" "$?" "$tmpfile" "$cmd"

# Add mail account
cmd="v-add-mail-account $user $domain mail-user p@ssw0rd"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Adding mail account" "$?" "$tmpfile" "$cmd"

# Add mail account alias
cmd="v-add-mail-account-alias $user $domain mail-user test-alias"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Adding mail account alias" "$?" "$tmpfile" "$cmd"

# Change mail account password
cmd="v-change-mail-account-password $user $domain mail-user testnew-p@ssw0rd"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Changing mail account password" "$?" "$tmpfile" "$cmd"

# Suspend mail account
cmd="v-suspend-mail-account $user $domain mail-user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Suspending mail account" "$?" "$tmpfile" "$cmd"

# Unsuspend mail account
cmd="v-unsuspend-mail-account $user $domain mail-user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Unsuspending mail account" "$?" "$tmpfile" "$cmd"

# Suspend mail domain
cmd="v-suspend-mail-domain $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Suspending mail domain $domain" "$?" "$tmpfile" "$cmd"

# Unuspend mail domain
cmd="v-unsuspend-mail-domain $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Unsuspending mail domain $domain" "$?" "$tmpfile" "$cmd"

# Rebuild mail domains
cmd="v-rebuild-mail-domains $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Changing mail account password" "$?" "$tmpfile" "$cmd"

# Delete mail account alias
cmd="v-delete-mail-account-alias $user $domain mail-user test-alias"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Delete mail account alias" "$?" "$tmpfile" "$cmd"

# Delete mail account
cmd="v-delete-mail-account $user $domain mail-user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Delete mail account" "$?" "$tmpfile" "$cmd"

# Delete mail domain
cmd="v-delete-mail-domain $user $domain"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[MAIL]: Delete mail domain" "$?" "$tmpfile" "$cmd"

echo

###########################################################################################
#
#  DATABASE (MYSQL/POSTGRESQL)
#
###########################################################################################

# Add mysql database
database=d$(random 4)
cmd="v-add-database $user $database $database dbp4ssw0rd mysql"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DB]: Create new SQL database" "$?" "$tmpfile" "$cmd"

# List databases
cmd="v-list-databases $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DB]: List all databases" "$?" "$tmpfile" "$cmd"

# Rebuild database
cmd="v-rebuild-database $user ${user}_${database}"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DB]: Rebuilding database" "$?" "$tmpfile" "$cmd"

# Delete database
cmd="v-delete-database $user ${user}_${database}"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DB]: Delete database" "$?" "$tmpfile" "$cmd"

echo

###########################################################################################
#
#  BACKUP
#
###########################################################################################

# Create backup
cmd="v-backup-user $user no"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[BACKUP]: Create backup archive" "$?" "$tmpfile" "$cmd"

# Get backup list
cmd="v-list-user-backups $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[BACKUP]: List backup archives" "$?" "$tmpfile" "$cmd"

# Restore backup
BACKUP_FILE=$(v-list-user-backups $user | grep $user | cut -d' ' -f1 | tail -n1)
cmd="v-restore-user $user $BACKUP_FILE"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[BACKUP]: Restore backup: $BACKUP_FILE" "$?" "$tmpfile" "$cmd"

echo

###########################################################################################
#
#  SYSTEM
#
###########################################################################################

# Change system configuration value
cmd="v-change-sys-config-value TEST_MODE true"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Change configuration value in hestia.conf" "$?" "$tmpfile" "$cmd"

# Change system theme
cmd="v-change-sys-theme dark"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Change system theme" "$?" "$tmpfile" "$cmd"

# Refresh system theme
cmd="v-refresh-sys-theme"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Refresh system theme assets" "$?" "$tmpfile" "$cmd"

# Copy hosting package
cmd="v-copy-user-package default $user-test"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Copy web hosting package" "$?" "$tmpfile" "$cmd"

# Delete hosting package
cmd="v-delete-user-package $user-test"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Delete web hosting package" "$?" "$tmpfile" "$cmd"

# List PHP versions
cmd="v-list-sys-php"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: List installed PHP versions" "$?" "$tmpfile" "$cmd"

# Update Firewall
cmd="v-update-firewall"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Update firewall" "$?" "$tmpfile" "$cmd"

# Update Firewall Ipset
cmd="v-update-firewall-ipset"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Update ipset rules" "$?" "$tmpfile" "$cmd"

# Change PMA/PGA alias
cmd="v-change-sys-db-alias pma phpMyAdmin"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Change phpMyAdmin alias" "$?" "$tmpfile" "$cmd"

# Change PMA/PGA alias
cmd="v-change-sys-db-alias pga phpPgAdmin"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Change phpPgAdmin alias" "$?" "$tmpfile" "$cmd"


# Add pgsql database
# database=d$(random 4)
# cmd="v-add-database $user $database $database dbp4ssw0rd pgsql"
# $cmd > $tmpfile 2>> $tmpfile
# echo_result "Adding pgsql database $database" "$?" "$tmpfile" "$cmd"

# Restart DNS
cmd="v-restart-dns"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Restart DNS service" "$?" "$tmpfile" "$cmd"

# Restart Proxy
cmd="v-restart-proxy"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Restart NGINX proxy service" "$?" "$tmpfile" "$cmd"

# Restart Mail
cmd="v-restart-mail"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Restart mail services" "$?" "$tmpfile" "$cmd"

# Restart FTP
cmd="v-restart-ftp"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Restart FTP service" "$?" "$tmpfile" "$cmd"

# Restart Web
cmd="v-restart-web"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[SYSTEM]: Restart web services" "$?" "$tmpfile" "$cmd"

# Rebuild user configs
cmd="v-rebuild-user $user yes"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Rebuilding user config" "$?" "$tmpfile" "$cmd"

# Update user stats
cmd="v-update-user-stats $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Update user statistics for $user" "$?" "$tmpfile" "$cmd"


# Update user disk stats
cmd="v-update-user-disk $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Update user disk usage for $user" "$?" "$tmpfile" "$cmd"


# Update user quota stats
cmd="v-update-user-quota $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Update quota information for $user" "$?" "$tmpfile" "$cmd"

echo
###########################################################################################
#
#  ADDITIONAL ACTIONS
#
###########################################################################################

# Change domain ownership between two accounts

cmd="v-change-domain-owner $domain admin"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DOMAINS]: Move $domain to admin" "$?" "$tmpfile" "$cmd"
cmd="v-change-domain-owner $domain $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[DOMAINS]: Move $domain to $user" "$?" "$tmpfile" "$cmd"

echo
###########################################################################################
#
#  TEST SUITE CLEAN-UP
#
###########################################################################################


# Delete user
cmd="v-delete-user $user"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[USER]: Deleting user $user" "$?" "$tmpfile" "$cmd"

# Delete ip address
cmd="v-delete-sys-ip 198.18.0.125"
$cmd > $tmpfile 2>> $tmpfile
echo_result "[IP]: Deleting IP 198.18.0.125" "$?" "$tmpfile" "$cmd"

