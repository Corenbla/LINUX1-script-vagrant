#!/bin/bash

echo 'Voici une liste des VMs:'
BOXES=$(vboxmanage list vms)

if [ ! "$BOXES" ]; then
  BOXES='                     Aucune pour l'\''instant!'
fi

echo -e "
+-------------------------\e[33mListe-des-VMs\e[0m-------------------------+
${BOXES}
+---------------------------------------------------------------+

"

echo -e "
  \e[1mQue souhaites-tu faire?\e[0m
  1) Créer une box Vagrant (Défaut)
  2) Eteindre une box Vagrant"
read -r action

case $action in
  2)
    echo 'Quelle box Vagrant souhaites-tu éteindre? (copie son nom et rentre le, si t'\''es pas content t'\''as qu'\''à le faire à la mano)'
    read -r SHUTDOWN
    vboxmanage controlvm "$SHUTDOWN" poweroff
    ;;
  *)
    echo "Création d'une nouvelle VM..."
    echo 'Quelle ip? 192.168.33.XX (XX entre 10 et 255)'
    read -r ip
    while [[ "$ip" -lt 10 || "$ip" -gt 255 || "$ip" =~ [^0-9] ]]; do #redemmande l'ip si elle n'est pas entre 10 et 255 ou si ce n'est pas un nombre (enfin ça tu le sais rien qu'en voyant la regex 😘 )
      echo 'ip doit être 192.168.33.XX, réentrer ip:'
      read -r ip
    done
    echo 'Quel nom de répertoire sync coté actuel? (ne rien mettre pour "./data")'
    read -r file
    echo 'Quel nom de répertoire sync coté VM? (ne rien mettre pour "/var/www/html/")'
    read -r fileVM
    echo 'Quel nom de VM? (ne rien mettre pour "Défaut")' #customise le nom de la VM et ajoute l'addresse ip du server à coté
    read -r nom
    echo -e "Quelle box? (ne rien mettre pour \"ubuntu/xenial64\")
\e[4mhttps://app.vagrantup.com/boxes/search\e[0m pour une liste des boxes disponible"
    read -r box
    nom="$nom - ip:192.168.33.$ip"

    # Options par défaut
    if [[ "$nom" == " - ip:192.168.33.$ip" ]]; then
      nom="Défaut-ip:192.168.33.$ip"
    fi

    if [[ "$file" == "" ]]; then
      file='data'
    fi

    if [[ "$fileVM" == "" ]]; then
      fileVM="/var/www/html/"
    fi

    if [ "$box" == "" ]; then
      box="ubuntu/xenial64"
    fi

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    echo "
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(\"2\") do |config|
  config.vm.box = \"$box\"
  config.vm.network \"private_network\", ip: \"192.168.33.$ip\"
  config.vm.synced_folder \"./$file\", \"$fileVM\"
  config.vm.provider \"virtualbox\" do |v|
    v.name = \"$nom\"
  end
end
" > ./Vagrantfile #Ficher de config de Vagrant

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    mkdir ./${file} #Dossier sync

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    echo "Et parce que je t'aime bien, je te met Adminer en cadeau..."
    wget -q https://github.com/vrana/adminer/releases/download/v4.7.1/adminer-4.7.1-mysql.php
    echo 'Cadeau installé sur la VM!'
    mv adminer-4.7.1-mysql.php ./${file}/adminer.php

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #Création du script d'installation une fois dans la VM

    # shellcheck disable=SC2016
    echo '
  #!/bin/bash

  echo "Choisis une version de PHP"
  select optPHP in php7.3 php7.2 php5.6; do
    sudo add-apt-repository ppa:ondrej/php -y
    sudo apt update
    sudo apt install apache2 -y
    sudo apt install ${optPHP} -y
    sudo apt install libapache2-mod-${optPHP} -y
    sudo apt install php-xdebug -y
    sudo apt install ${optPHP}-mysql -y
    sudo apt install ${optPHP}-zip -y
    sudo apt install ${optPHP}-mbstring -y
    sudo apt install ${optPHP}-dom -y
    sudo apt install ${optPHP}-curl -y
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password 1234"
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password 1234"
    sudo apt install mysql-server -y

    php -r "copy('\''https://getcomposer.org/installer'\'', '\''composer-setup.php'\'');"
    php -r "if (hash_file('\''sha384'\'', '\''composer-setup.php'\'') === '\''a5c698ffe4b8e849a443b120cd5ba38043260d5c4023dbf93e1558871f1f07f58274fc6f4c93bcfd858c6bd0775cd8d1'\'') { echo '\''Installer verified'\''; } else { echo '\''Installer corrupt'\''; unlink('\''composer-setup.php'\''); } echo PHP_EOL;"
    php composer-setup.php
    php -r "unlink('\''composer-setup.php'\'');"
    sudo mv composer.phar /usr/local/bin/composer

    case $optPHP in
    php5.6)
      sudo sed -i '\''466s/Off/On/'\'' /etc/php/5.6/apache2/php.ini
      sudo sed -i '\''477s/Off/On/'\'' /etc/php/5.6/apache2/php.ini
      sudo sed -i '\''16s/www-data/vagrant/'\'' /etc/apache2/envvars
      sudo sed -i '\''17s/www-data/vagrant/'\'' /etc/apache2/envvars
      ;;
    *)
      sudo sed -i '\''474s/Off/On/'\'' /etc/php/7.3/apache2/php.ini
      sudo sed -i '\''485s/Off/On/'\'' /etc/php/7.3/apache2/php.ini
      sudo sed -i '\''16s/www-data/vagrant/'\'' /etc/apache2/envvars
      sudo sed -i '\''17s/www-data/vagrant/'\'' /etc/apache2/envvars
      ;;
    esac

    sudo a2enmod rewrite

    sudo service apache2 restart
    echo "Done! Ton mot de passe mysql est 1234, change le!"
    rm /var/www/html/install.sh
    break
  done
  ' > ./$file/install.sh
    ;;
esac

if [ "$action" -eq 2 ]; then #Quit early if a VM was shut down
  echo -e "
  \e[1mJob's done!\e[0m
    "
  exit
fi

vagrant up
echo -e "C'est fini! n'oublies pas de lancer \e[42m${fileVM}install.sh\e[0m pour l'installation des paquets!"
read -rp "Lancer la vagrant? [Y/n]" LAUNCH
case $LAUNCH in
  n* | N*)
    echo "Ok, c'est quand même dommage d'avoir fait tout ça pour rien...
    "
    exit
    ;;
  *)
    vagrant ssh # To adventure!
    ;;
esac
