#!/bin/bash

# Wait for the MySQL service to become available
while [ true ]; do
   echo "show databases" | mysql -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASSWORD &> /dev/null

   if [ $? != 0 ]; then
      echo "Waiting for MySQL to become available"
      sleep 3
   else
      break
   fi
done

# Finally, make sure we have an SSL certificate in place
if [ ! -e /etc/apache2/ssl/apache.crt ]; then
   echo "Generating new SSL certificate"
   openssl req -subj '/CN=example.com/O=First/C=US' -new -newkey rsa:4096 -sha256 -days 365 -nodes -x509 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
else
   echo "Using existing SSL certificate"
fi

# Always run migrations
/usr/bin/python /home/first/manage.py migrate

# up engine
python /home/first/utilities/engine_shell.py install first.engines.exact_match ExactMatchEngine "root@localhost"
python /home/first/utilities/engine_shell.py install first.engines.mnemonic_hash MnemonicHashEngine "root@localhost"
python /home/first/utilities/engine_shell.py install first.engines.basic_masking BasicMaskingEngine "root@localhost"

# Finally, start up the apache service
/usr/sbin/apache2ctl -D FOREGROUND


