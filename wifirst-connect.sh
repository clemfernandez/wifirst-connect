#!/bin/sh

LOGIN=$1
PASSWORD=$2

# TODO: Add option to configure temp directory
TMP=/tmp
COOKIES=cookies.txt

UA="Mozilla/5.0 (X11; Linux x86_64; rv:62.0) Gecko/20100101 Firefox/62.0"

PORTAL_URL="https://connect.wifirst.net/?perform=true"
CONNECT_URL="https://selfcare.wifirst.net/sessions"
PRIV_CONNECT_URL="https://wireless.wifirst.net:8090/goform/HtmlLoginRequest"

TOKEN_RGX="s/^.*authenticity_token.*value=\"\(.*\)\" \/><\/div>/\1/p"
USERNAME_RGX="s/^.*username.*value=\"\(.*\)\" \/>/\1/p"
PASSWORD_RGX="s/^.*password.*value=\"\(.*\)\" \/>/\1/p"

usage() { echo "Usage: wifirst-connect LOGIN PASSWORD"; }

if [ -z "$LOGIN" ] || [ -z "$PASSWORD" ]; then
	usage
	exit 1
fi

cd $TMP

PORTAL_RESP=$(curl -sLkb $COOKIES -c $COOKIES -H "User-Agent: $UA" $PORTAL_URL)
# echo "portal: "
# echo $PORTAL_RESP

CSRF_TOKEN=$(echo "$PORTAL_RESP" | sed -n "$TOKEN_RGX")
# echo "token: "
# echo $CSRF_TOKEN
# echo ""

CONNECT_RESP=$(curl -sLkb $COOKIES -c $COOKIES -H "User-Agent: $UA" \
	--data-urlencode "utf8=&#x2713;" \
	--data-urlencode "authenticity_token=$CSRF_TOKEN" \
	--data-urlencode "login=$LOGIN" \
	--data-urlencode "password=$PASSWORD" \
	$CONNECT_URL)
# echo "connect: "
# echo $CONNECT_RESP

PRIV_USERNAME=$(echo "$CONNECT_RESP" | sed -n "$USERNAME_RGX")
PRIV_PASSWORD=$(echo "$CONNECT_RESP" | sed -n "$PASSWORD_RGX")
# echo "priv usr: "
# echo $PRIV_USERNAME
# echo "priv passwd: "
# echo $PRIV_PASSWORD
# echo ""

PRIV_CONNECT_RESP=$(curl -sLkb $COOKIES -c $COOKIES -H "User-Agent: $UA" \
	--data-urlencode "commit=Se connecter" \
	--data-urlencode "username=$PRIV_USERNAME" \
	--data-urlencode "password=$PRIV_PASSWORD" \
	--data-urlencode "qos_class=" \
	--data-urlencode "success_url=https://apps.wifirst.net/?redirected=true" \
	--data-urlencode "error_url=https://connect.wifirst.net/login_error" \
	$PRIV_CONNECT_URL)
# echo "priv: "
# echo $PRIV_CONNECT_RESP

rm $COOKIES
