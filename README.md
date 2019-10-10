# ScriptsVirtualMachine

**How to:**

- Place le script dans le dossier qui servira de VM
- Lance le depuis un terminal
- Suis les instructions, tu peux éteindre une VM ou en créer une.
- Une fois dans la vm, faire: 
```shell script
$ bash /var/www/html/install.sh
```
- Choisir sa version de PHP
- Attendre l'installation des paquets
- C'est fini!

**Ce que ce script installe:**

- Apache 2
- Libapache
- Php 7.3 / 7.2 / 5.6
- **Active les erreurs Php**
- MySQL
- Adminer

**Infos:**

- Mot de passe MySQL de `root@localhost` : `1234` (`0000` peut causer des erreurs avec certains frameworks commençant par Sym et finissant par fony!)


*Si quelque chose cloche, ne marche pas ou si vous avez des question, envoyez moi un email!  corenbla@gmail.com*
