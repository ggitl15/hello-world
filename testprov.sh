










start_seconds="$(date +%s)"








apt_package_install_list=()




apt_package_check_list=(

  
  
  
  
  
  php5-fpm
  php5-cli

  
  php5-common
  php5-dev

  
  php5-memcache
  php5-imagick
  php5-mcrypt
  php5-mysql
  php5-imap
  php5-curl
  php-pear
  php5-gd

  
  nginx

  
  memcached

  
  mysql-server

  
  imagemagick
  subversion
  git-core
  zip
  unzip
  ngrep
  curl
  make
  vim
  colordiff
  postfix

  
  ntp

  
  gettext

  
  graphviz

  
  
  
  dos2unix

  
  g++
  nodejs

  
  libsqlite3-dev

)



network_detection() {
  
  
  
  
  
  if [[ "$(wget --tries=3 --timeout=5 --spider http://google.com 2>&1 | grep 'connected')" ]]; then
    echo "Network connection detected..."
    ping_result="Connected"
  else
    echo "Network connection not detected. Unable to reach google.com..."
    ping_result="Not Connected"
  fi
}

network_check() {
  network_detection
  if [[ ! "$ping_result" == "Connected" ]]; then
    echo -e "\nNo network connection available, skipping package installation"
    exit 0
  fi
}

noroot() {
  sudo -EH -u "vagrant" "$@";
}

profile_setup() {
  
  cp "/srv/config/bash_profile" "/home/vagrant/.bash_profile"
  cp "/srv/config/bash_aliases" "/home/vagrant/.bash_aliases"
  cp "/srv/config/vimrc" "/home/vagrant/.vimrc"

  if [[ ! -d "/home/vagrant/.subversion" ]]; then
    mkdir "/home/vagrant/.subversion"
  fi

  cp "/srv/config/subversion-servers" "/home/vagrant/.subversion/servers"

  if [[ ! -d "/home/vagrant/bin" ]]; then
    mkdir "/home/vagrant/bin"
  fi

  rsync -rvzh --delete "/srv/config/homebin/" "/home/vagrant/bin/"

  echo " * Copied /srv/config/bash_profile                      to /home/vagrant/.bash_profile"
  echo " * Copied /srv/config/bash_aliases                      to /home/vagrant/.bash_aliases"
  echo " * Copied /srv/config/vimrc                             to /home/vagrant/.vimrc"
  echo " * Copied /srv/config/subversion-servers                to /home/vagrant/.subversion/servers"
  echo " * rsync'd /srv/config/homebin                          to /home/vagrant/bin"

  
  if [[ -f "/srv/config/bash_prompt" ]]; then
    cp "/srv/config/bash_prompt" "/home/vagrant/.bash_prompt"
    echo " * Copied /srv/config/bash_prompt to /home/vagrant/.bash_prompt"
  fi
}

package_check() {
  
  
  local pkg
  local package_version

  for pkg in "${apt_package_check_list[@]}"; do
    package_version=$(dpkg -s "${pkg}" 2>&1 | grep 'Version:' | cut -d " " -f 2)
    if [[ -n "${package_version}" ]]; then
      space_count="$(expr 20 - "${
      pack_space_count="$(expr 30 - "${
      real_space="$(expr ${space_count} + ${pack_space_count} + ${
      printf " * $pkg %${real_space}.${
    else
      echo " *" $pkg [not installed]
      apt_package_install_list+=($pkg)
    fi
  done
}

package_install() {
  package_check

  
  
  
  
  
  echo mysql-server mysql-server/root_password password "root" | debconf-set-selections
  echo mysql-server mysql-server/root_password_again password "root" | debconf-set-selections

  
  
  
  
  
  
  echo postfix postfix/main_mailer_type select Internet Site | debconf-set-selections
  echo postfix postfix/mailname string vvv | debconf-set-selections

  
  echo "inet_protocols = ipv4" >> "/etc/postfix/main.cf"

  
  ln -sf /srv/config/apt-source-append.list /etc/apt/sources.list.d/vvv-sources.list
  echo "Linked custom apt sources"

  if [[ ${
    echo -e "No apt packages to install.\n"
  else
    
    
    

    
    echo "Applying Nginx signing key..."
    wget --quiet "http://nginx.org/keys/nginx_signing.key" -O- | apt-key add -

    
    apt-key adv --quiet --keyserver "hkp://keyserver.ubuntu.com:80" --recv-key C7917B12 2>&1 | grep "gpg:"
    apt-key export C7917B12 | apt-key add -

    
    echo "Running apt-get update..."
    apt-get update -y

    
    echo "Installing apt-get packages..."
    apt-get install -y ${apt_package_install_list[@]}

    
    apt-get clean
  fi
}

tools_install() {
  
  
  
  npm install -g npm
  npm install -g npm-check-updates

  
  
  
  
  
  pecl install xdebug

  
  
  
  
  if [[ -f /usr/bin/ack ]]; then
    echo "ack-grep already installed"
  else
    echo "Installing ack-grep as ack"
    curl -s http://beyondgrep.com/ack-2.14-single-file > "/usr/bin/ack" && chmod +x "/usr/bin/ack"
  fi

  
  
  
  if [[ ! -n "$(composer --version --no-ansi | grep 'Composer version')" ]]; then
    echo "Installing Composer..."
    curl -sS "https://getcomposer.org/installer" | php
    chmod +x "composer.phar"
    mv "composer.phar" "/usr/local/bin/composer"
  fi

  if [[ -f /vagrant/provision/github.token ]]; then
    ghtoken=`cat /vagrant/provision/github.token`
    composer config --global github-oauth.github.com $ghtoken
    echo "Your personal GitHub token is set for Composer."
  fi

  
  
  if [[ -n "$(composer --version --no-ansi | grep 'Composer version')" ]]; then
    echo "Updating Composer..."
    COMPOSER_HOME=/usr/local/src/composer composer self-update
    COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update phpunit/phpunit:4.8.*
    COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update phpunit/php-invoker:1.1.*
    COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update mockery/mockery:0.9.*
    COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update d11wtq/boris:v1.0.8
    COMPOSER_HOME=/usr/local/src/composer composer -q global config bin-dir /usr/local/bin
    COMPOSER_HOME=/usr/local/src/composer composer global update
  fi

  
  
  
  
  if [[ "$(grunt --version)" ]]; then
    echo "Updating Grunt CLI"
    npm update -g grunt-cli &>/dev/null
    npm update -g grunt-sass &>/dev/null
    npm update -g grunt-cssjanus &>/dev/null
    npm update -g grunt-rtlcss &>/dev/null
  else
    echo "Installing Grunt CLI"
    npm install -g grunt-cli &>/dev/null
    npm install -g grunt-sass &>/dev/null
    npm install -g grunt-cssjanus &>/dev/null
    npm install -g grunt-rtlcss &>/dev/null
  fi

  
  
  
  
  echo "Adding graphviz symlink for Webgrind..."
  ln -sf "/usr/bin/dot" "/usr/local/bin/dot"
}

nginx_setup() {
  
  if [[ ! -e /etc/nginx/server.key ]]; then
	  echo "Generate Nginx server private key..."
	  vvvgenrsa="$(openssl genrsa -out /etc/nginx/server.key 2048 2>&1)"
	  echo "$vvvgenrsa"
  fi
  if [[ ! -e /etc/nginx/server.crt ]]; then
	  echo "Sign the certificate using the above private key..."
	  vvvsigncert="$(openssl req -new -x509 \
            -key /etc/nginx/server.key \
            -out /etc/nginx/server.crt \
            -days 3650 \
            -subj /CN=*.wordpress-develop.dev/CN=*.wordpress.dev/CN=*.vvv.dev/CN=*.wordpress-trunk.dev 2>&1)"
	  echo "$vvvsigncert"
  fi

  echo -e "\nSetup configuration files..."

  
  cp "/srv/config/init/vvv-start.conf" "/etc/init/vvv-start.conf"
  echo " * Copied /srv/config/init/vvv-start.conf               to /etc/init/vvv-start.conf"

  
  cp "/srv/config/nginx-config/nginx.conf" "/etc/nginx/nginx.conf"
  cp "/srv/config/nginx-config/nginx-wp-common.conf" "/etc/nginx/nginx-wp-common.conf"
  if [[ ! -d "/etc/nginx/custom-sites" ]]; then
    mkdir "/etc/nginx/custom-sites/"
  fi
  rsync -rvzh --delete "/srv/config/nginx-config/sites/" "/etc/nginx/custom-sites/"

  echo " * Copied /srv/config/nginx-config/nginx.conf           to /etc/nginx/nginx.conf"
  echo " * Copied /srv/config/nginx-config/nginx-wp-common.conf to /etc/nginx/nginx-wp-common.conf"
  echo " * Rsync'd /srv/config/nginx-config/sites/              to /etc/nginx/custom-sites"
}

phpfpm_setup() {
  
  cp "/srv/config/php5-fpm-config/php5-fpm.conf" "/etc/php5/fpm/php5-fpm.conf"
  cp "/srv/config/php5-fpm-config/www.conf" "/etc/php5/fpm/pool.d/www.conf"
  cp "/srv/config/php5-fpm-config/php-custom.ini" "/etc/php5/fpm/conf.d/php-custom.ini"
  cp "/srv/config/php5-fpm-config/opcache.ini" "/etc/php5/fpm/conf.d/opcache.ini"
  cp "/srv/config/php5-fpm-config/xdebug.ini" "/etc/php5/mods-available/xdebug.ini"

  
  XDEBUG_PATH=$( find /usr -name 'xdebug.so' | head -1 )
  sed -i "1izend_extension=\"$XDEBUG_PATH\"" "/etc/php5/mods-available/xdebug.ini"

  echo " * Copied /srv/config/php5-fpm-config/php5-fpm.conf     to /etc/php5/fpm/php5-fpm.conf"
  echo " * Copied /srv/config/php5-fpm-config/www.conf          to /etc/php5/fpm/pool.d/www.conf"
  echo " * Copied /srv/config/php5-fpm-config/php-custom.ini    to /etc/php5/fpm/conf.d/php-custom.ini"
  echo " * Copied /srv/config/php5-fpm-config/opcache.ini       to /etc/php5/fpm/conf.d/opcache.ini"
  echo " * Copied /srv/config/php5-fpm-config/xdebug.ini        to /etc/php5/mods-available/xdebug.ini"

  
  cp "/srv/config/memcached-config/memcached.conf" "/etc/memcached.conf"

  echo " * Copied /srv/config/memcached-config/memcached.conf   to /etc/memcached.conf"
}

mysql_setup() {
  
  local exists_mysql

  exists_mysql="$(service mysql status)"
  if [[ "mysql: unrecognized service" != "${exists_mysql}" ]]; then
    echo -e "\nSetup MySQL configuration file links..."

    
    cp "/srv/config/mysql-config/my.cnf" "/etc/mysql/my.cnf"
    cp "/srv/config/mysql-config/root-my.cnf" "/home/vagrant/.my.cnf"

    echo " * Copied /srv/config/mysql-config/my.cnf               to /etc/mysql/my.cnf"
    echo " * Copied /srv/config/mysql-config/root-my.cnf          to /home/vagrant/.my.cnf"

    
    
    
    if [[ "mysql stop/waiting" == "${exists_mysql}" ]]; then
      echo "service mysql start"
      service mysql start
      else
      echo "service mysql restart"
      service mysql restart
    fi

    
    
    
    
    if [[ -f "/srv/database/init-custom.sql" ]]; then
      mysql -u "root" -p"root" < "/srv/database/init-custom.sql"
      echo -e "\nInitial custom MySQL scripting..."
    else
      echo -e "\nNo custom MySQL scripting found in database/init-custom.sql, skipping..."
    fi

    
    
    mysql -u "root" -p"root" < "/srv/database/init.sql"
    echo "Initial MySQL prep..."

    
    
    "/srv/database/import-sql.sh"
  else
    echo -e "\nMySQL is not installed. No databases imported."
  fi
}

mailcatcher_setup() {
  
  
  
  
  local pkg

  rvm_version="$(/usr/bin/env rvm --silent --version 2>&1 | grep 'rvm ' | cut -d " " -f 2)"
  if [[ -n "${rvm_version}" ]]; then
    pkg="RVM"
    space_count="$(( 20 - ${
    pack_space_count="$(( 30 - ${
    real_space="$(( ${space_count} + ${pack_space_count} + ${
    printf " * $pkg %${real_space}.${
  else
    
    
    gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys D39DC0E3
    gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys BF04FF17

    printf " * RVM [not installed]\n Installing from source"
    curl --silent -L "https://get.rvm.io" | sudo bash -s stable --ruby
    source "/usr/local/rvm/scripts/rvm"
  fi

  mailcatcher_version="$(/usr/bin/env mailcatcher --version 2>&1 | grep 'mailcatcher ' | cut -d " " -f 2)"
  if [[ -n "${mailcatcher_version}" ]]; then
    pkg="Mailcatcher"
    space_count="$(( 20 - ${
    pack_space_count="$(( 30 - ${
    real_space="$(( ${space_count} + ${pack_space_count} + ${
    printf " * $pkg %${real_space}.${
  else
    echo " * Mailcatcher [not installed]"
    /usr/bin/env rvm default@mailcatcher --create do gem install mailcatcher --no-rdoc --no-ri
    /usr/bin/env rvm wrapper default@mailcatcher --no-prefix mailcatcher catchmail
  fi

  if [[ -f "/etc/init/mailcatcher.conf" ]]; then
    echo " *" Mailcatcher upstart already configured.
  else
    cp "/srv/config/init/mailcatcher.conf"  "/etc/init/mailcatcher.conf"
    echo " * Copied /srv/config/init/mailcatcher.conf    to /etc/init/mailcatcher.conf"
  fi

  if [[ -f "/etc/php5/mods-available/mailcatcher.ini" ]]; then
    echo " *" Mailcatcher php5 fpm already configured.
  else
    cp "/srv/config/php5-fpm-config/mailcatcher.ini" "/etc/php5/mods-available/mailcatcher.ini"
    echo " * Copied /srv/config/php5-fpm-config/mailcatcher.ini    to /etc/php5/mods-available/mailcatcher.ini"
  fi
}

services_restart() {
  
  
  
  echo -e "\nRestart services..."
  service nginx restart
  service memcached restart
  service mailcatcher restart

  
  php5dismod xdebug

  
  php5enmod mcrypt

  
  php5enmod mailcatcher

  service php5-fpm restart

  
  
  usermod -a -G www-data vagrant
}

wp_cli() {
  
  if [[ ! -d "/srv/www/wp-cli" ]]; then
    echo -e "\nDownloading wp-cli, see http://wp-cli.org"
    git clone "https://github.com/wp-cli/wp-cli.git" "/srv/www/wp-cli"
    cd /srv/www/wp-cli
    composer install
  else
    echo -e "\nUpdating wp-cli..."
    cd /srv/www/wp-cli
    git pull --rebase origin master
    composer update
  fi
  
  ln -sf "/srv/www/wp-cli/bin/wp" "/usr/local/bin/wp"
}

memcached_admin() {
  
  
  if [[ ! -d "/srv/www/default/memcached-admin" ]]; then
    echo -e "\nDownloading phpMemcachedAdmin, see https://github.com/wp-cloud/phpmemcacheadmin"
    cd /srv/www/default
    wget -q -O phpmemcachedadmin.tar.gz "https://github.com/wp-cloud/phpmemcacheadmin/archive/1.2.2.1.tar.gz"
    tar -xf phpmemcachedadmin.tar.gz
    mv phpmemcacheadmin* memcached-admin
    rm phpmemcachedadmin.tar.gz
  else
    echo "phpMemcachedAdmin already installed."
  fi
}

opcached_status(){
  
  
  if [[ ! -d "/srv/www/default/opcache-status" ]]; then
    echo -e "\nDownloading Opcache Status, see https://github.com/rlerdorf/opcache-status/"
    cd /srv/www/default
    git clone "https://github.com/rlerdorf/opcache-status.git" opcache-status
  else
    echo -e "\nUpdating Opcache Status"
    cd /srv/www/default/opcache-status
    git pull --rebase origin master
  fi
}

webgrind_install() {
  
  
  if [[ ! -d "/srv/www/default/webgrind" ]]; then
    echo -e "\nDownloading webgrind, see https://github.com/michaelschiller/webgrind.git"
    git clone "https://github.com/michaelschiller/webgrind.git" "/srv/www/default/webgrind"
  else
    echo -e "\nUpdating webgrind..."
    cd /srv/www/default/webgrind
    git pull --rebase origin master
  fi
}

php_codesniff() {
  
  if [[ ! -d "/srv/www/phpcs" ]]; then
    echo -e "\nDownloading PHP_CodeSniffer (phpcs), see https://github.com/squizlabs/PHP_CodeSniffer"
    git clone -b master "https://github.com/squizlabs/PHP_CodeSniffer.git" "/srv/www/phpcs"
  else
    cd /srv/www/phpcs
    if [[ $(git rev-parse --abbrev-ref HEAD) == 'master' ]]; then
      echo -e "\nUpdating PHP_CodeSniffer (phpcs)..."
      git pull --no-edit origin master
    else
      echo -e "\nSkipped updating PHP_CodeSniffer since not on master branch"
    fi
  fi

  
  if [[ ! -d "/srv/www/phpcs/CodeSniffer/Standards/WordPress" ]]; then
    echo -e "\nDownloading WordPress-Coding-Standards, sniffs for PHP_CodeSniffer, see https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards"
    git clone -b master "https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git" "/srv/www/phpcs/CodeSniffer/Standards/WordPress"
  else
    cd /srv/www/phpcs/CodeSniffer/Standards/WordPress
    if [[ $(git rev-parse --abbrev-ref HEAD) == 'master' ]]; then
      echo -e "\nUpdating PHP_CodeSniffer WordPress Coding Standards..."
      git pull --no-edit origin master
    else
      echo -e "\nSkipped updating PHPCS WordPress Coding Standards since not on master branch"
    fi
  fi

  
  /srv/www/phpcs/scripts/phpcs --config-set installed_paths ./CodeSniffer/Standards/WordPress/
  /srv/www/phpcs/scripts/phpcs --config-set default_standard WordPress-Core
  /srv/www/phpcs/scripts/phpcs -i
}

phpmyadmin_setup() {
  
  if [[ ! -d /srv/www/default/database-admin ]]; then
    echo "Downloading phpMyAdmin..."
    cd /srv/www/default
    wget -q -O phpmyadmin.tar.gz "https://files.phpmyadmin.net/phpMyAdmin/4.4.10/phpMyAdmin-4.4.10-all-languages.tar.gz"
    tar -xf phpmyadmin.tar.gz
    mv phpMyAdmin-4.4.10-all-languages database-admin
    rm phpmyadmin.tar.gz
  else
    echo "PHPMyAdmin already installed."
  fi
  cp "/srv/config/phpmyadmin-config/config.inc.php" "/srv/www/default/database-admin/"
}

wordpress_default() {
  
  if [[ ! -d "/srv/www/wordpress-default" ]]; then
    echo "Downloading WordPress Stable, see http://wordpress.org/"
    cd /srv/www/
    curl -L -O "https://wordpress.org/latest.tar.gz"
    noroot tar -xvf latest.tar.gz
    mv wordpress wordpress-default
    rm latest.tar.gz
    cd /srv/www/wordpress-default
    echo "Configuring WordPress Stable..."
    noroot wp core config --dbname=wordpress_default --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('/^(local.wordpress.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
}

define( 'WP_DEBUG', true );
PHP
    echo "Installing WordPress Stable..."
    noroot wp core install --url=local.wordpress.dev --quiet --title="Local WordPress Dev" --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"
  else
    echo "Updating WordPress Stable..."
    cd /srv/www/wordpress-default
    noroot wp core upgrade
  fi
}

wpsvn_check() {
  
  svn_test=$( svn status -u "/srv/www/wordpress-develop/" 2>&1 );

  if [[ "$svn_test" == *"svn upgrade"* ]]; then
  
    for repo in $(find /srv/www -maxdepth 5 -type d -name '.svn'); do
      svn upgrade "${repo/%\.svn/}"
    done
  fi;
}

wordpress_trunk() {
  
  if [[ ! -d "/srv/www/wordpress-trunk" ]]; then
    echo "Checking out WordPress trunk from core.svn, see https://core.svn.wordpress.org/trunk"
    svn checkout "https://core.svn.wordpress.org/trunk/" "/srv/www/wordpress-trunk"
    cd /srv/www/wordpress-trunk
    echo "Configuring WordPress trunk..."
    noroot wp core config --dbname=wordpress_trunk --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('/^(local.wordpress-trunk.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
}

define( 'WP_DEBUG', true );
PHP
    echo "Installing WordPress trunk..."
    noroot wp core install --url=local.wordpress-trunk.dev --quiet --title="Local WordPress Trunk Dev" --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"
  else
    echo "Updating WordPress trunk..."
    cd /srv/www/wordpress-trunk
    svn up
  fi
}

wordpress_develop(){
  
  if [[ ! -d "/srv/www/wordpress-develop" ]]; then
    echo "Checking out WordPress trunk from develop.svn, see https://develop.svn.wordpress.org/trunk"
    svn checkout "https://develop.svn.wordpress.org/trunk/" "/srv/www/wordpress-develop"
    cd /srv/www/wordpress-develop/src/
    echo "Configuring WordPress develop..."
    noroot wp core config --dbname=wordpress_develop --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('/^(src|build)(.wordpress-develop.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
} else if ( 'build' === basename( dirname( __FILE__ ) ) ) {
// Allow (src|build).wordpress-develop.dev to share the same Database
define( 'WP_HOME', 'http://build.wordpress-develop.dev' );
define( 'WP_SITEURL', 'http://build.wordpress-develop.dev' );
}

define( 'WP_DEBUG', true );
PHP
    echo "Installing WordPress develop..."
    noroot wp core install --url=src.wordpress-develop.dev --quiet --title="WordPress Develop" --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"
    cp /srv/config/wordpress-config/wp-tests-config.php /srv/www/wordpress-develop/
    cd /srv/www/wordpress-develop/
    echo "Running npm install for the first time, this may take several minutes..."
    noroot npm install &>/dev/null
  else
    echo "Updating WordPress develop..."
    cd /srv/www/wordpress-develop/
    if [[ -e .svn ]]; then
      svn up
    else
      if [[ $(git rev-parse --abbrev-ref HEAD) == 'master' ]]; then
        git pull --no-edit git://develop.git.wordpress.org/ master
      else
        echo "Skip auto git pull on develop.git.wordpress.org since not on master branch"
      fi
    fi
    echo "Updating npm packages..."
    noroot npm install &>/dev/null
  fi

  if [[ ! -d "/srv/www/wordpress-develop/build" ]]; then
    echo "Initializing grunt in WordPress develop... This may take a few moments."
    cd /srv/www/wordpress-develop/
    grunt
  fi
}

custom_vvv(){
  
  
  
  
  find /etc/nginx/custom-sites -name 'vvv-auto-*.conf' -exec rm {} \;

  
  for SITE_CONFIG_FILE in $(find /srv/www -maxdepth 5 -name 'vvv-init.sh'); do
    DIR="$(dirname "$SITE_CONFIG_FILE")"
    (
    cd "$DIR"
    source vvv-init.sh
    )
  done

  
  for SITE_CONFIG_FILE in $(find /srv/www -maxdepth 5 -name 'vvv-nginx.conf'); do
    DEST_CONFIG_FILE=${SITE_CONFIG_FILE//\/srv\/www\//}
    DEST_CONFIG_FILE=${DEST_CONFIG_FILE//\//\-}
    DEST_CONFIG_FILE=${DEST_CONFIG_FILE/%-vvv-nginx.conf/}
    DEST_CONFIG_FILE="vvv-auto-$DEST_CONFIG_FILE-$(md5sum <<< "$SITE_CONFIG_FILE" | cut -c1-32).conf"
    
    
    
    DIR="$(dirname "$SITE_CONFIG_FILE")"
    sed "s
  done

  
  
  
  
  
  echo "Cleaning the virtual machine's /etc/hosts file..."
  sed -n '/
  mv /tmp/hosts /etc/hosts
  echo "Adding domains to the virtual machine's /etc/hosts file..."
  find /srv/www/ -maxdepth 5 -name 'vvv-hosts' | \
  while read hostfile; do
    while IFS='' read -r line || [ -n "$line" ]; do
      if [[ "
        if [[ -z "$(grep -q "^127.0.0.1 $line$" /etc/hosts)" ]]; then
          echo "127.0.0.1 $line 
          echo " * Added $line from $hostfile"
        fi
      fi
    done < "$hostfile"
  done
}




network_check

echo "Bash profile setup and directories."
profile_setup

network_check

echo " "
echo "Main packages check and install."
package_install
tools_install
nginx_setup
mailcatcher_setup
phpfpm_setup
services_restart
mysql_setup

network_check

echo " "
echo "Installing/updating wp-cli and debugging tools"

wp_cli
memcached_admin
opcached_status
webgrind_install
php_codesniff
phpmyadmin_setup

network_check

echo " "
echo "Installing/updating WordPress Stable, Trunk & Develop"

wordpress_default
wpsvn_check
wordpress_trunk
wordpress_develop


echo " "
echo "VVV custom site import"
custom_vvv



end_seconds="$(date +%s)"
echo "-----------------------------"
echo "Provisioning complete in "$((${end_seconds} - ${start_seconds}))" seconds"
echo "For further setup instructions, visit http://vvv.dev"
