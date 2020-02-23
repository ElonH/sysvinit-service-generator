#!/bin/bash

SERVICE_FILE=$(mktemp)

if [ ! -e service.sh ]; then
  echo -e "--- Download template ---"
  echo -e "I'll now download the service.sh, because is is not downloaded."
  echo -e "..."
  wget -q https://raw.githubusercontent.com/elonh/sample-service-script/master/service.sh
  if [ "$?" != 0 ]; then
    echo -e "I could not download the template!"
    echo -e "You should now download the service.sh file manualy. Run therefore:"
    echo -e "wget https://raw.githubusercontent.com/elonh/sample-service-script/master/service.sh"
    exit 1
  else
    echo -e "I donloaded the tmplate sucessfully"
    echo -e ""
  fi
fi


echo -e "--- Copy template ---"
cp service.sh "$SERVICE_FILE"
chmod +x "$SERVICE_FILE"
echo -e ""

echo -e "--- Customize ---"
echo -e "I'll now ask you some information to customize script"
echo -e "Press Ctrl+C anytime to abort."
echo -e "Empty values are not accepted."
echo -e ""

prompt_token() {
  local VAL=""
  if [ "$3" = "" ]; then
    while [ "$VAL" = "" ]; do
      echo -e -n "${2:-$1} : "
      read -e -p -r VAL
      if [ "$VAL" = "" ]; then
        echo -e "Please provide a value"
      fi
    done
  else
    VAL=${@:3:($#-2)}
  fi
  VAL=$(printf '%s' "$VAL")
  eval $1=$VAL
  local rstr=$(printf '%q' "$VAL")
  rstr=$(echo -e $rstr | sed -e 's/[\/&]/\\&/g') # escape search string for sed http://stackoverflow.com/questions/407523/escape-a-string-for-a-sed-replace-pattern
  sed -i "s/<$1>/$rstr/g" $SERVICE_FILE
}

prompt_token 'NAME'        'Service name' $1
if [ -f "/etc/init.d/$NAME" ]; then
  echo -e "Error: service '$NAME' already exists"
  exit 1
fi

prompt_token 'DESCRIPTION' ' Description' $2
prompt_token 'COMMAND'     '     Command' $3
prompt_token 'USERNAME'    '        User' $4
if ! id -u "$USERNAME" &> /dev/null; then
  echo -e "Error: user '$USERNAME' not found"
  exit 1
fi

echo -e ""

echo -e "--- Installation ---"
if [ ! -w /etc/init.d ]; then
  echo -e "You didn't give me enough permissions to install service myself."
  echo -e "That's smart, always be really cautious with third-party shell scripts!"
  echo -e "You should now type those commands as superuser to install and run your service:"
  echo -e ""
  echo -e "   mv \"$SERVICE_FILE\" \"/etc/init.d/$NAME\""
  echo -e "   touch \"/var/log/$NAME.log\" && chown \"$USERNAME\" \"/var/log/$NAME.log\""
  echo -e "   update-rc.d \"$NAME\" defaults"
  echo -e "   service \"$NAME\" start"
else
  echo -e "1. mv \"$SERVICE_FILE\" \"/etc/init.d/$NAME\""
  mv -v "$SERVICE_FILE" "/etc/init.d/$NAME"
  echo -e "2. touch \"/var/log/$NAME.log\" && chown \"$USERNAME\" \"/var/log/$NAME.log\""
  touch "/var/log/$NAME.log" && chown "$USERNAME" "/var/log/$NAME.log"
  echo -e "3. update-rc.d \"$NAME\" defaults"
  update-rc.d "$NAME" defaults
  echo -e "4. service \"$NAME\" start"
  service "$NAME" start
fi

echo -e ""
echo -e "---Uninstall instructions ---"
echo -e "The service can uninstall itself:"
echo -e "    service \"$NAME\" uninstall"
echo -e "It will simply run update-rc.d -f \"$NAME\" remove && rm -f \"/etc/init.d/$NAME\""
echo -e ""
echo -e "--- Terminated ---"
