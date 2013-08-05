### Librairie Ruby d'accès au Hub Dilicom

Interface fortement objet pour les services SOAP du Hub Dilicom https://hub-dilicom.centprod.com/documentation/doku.php?id=hub_principal:start

### Usage

Création du client HUB :
```ruby
client=HubDilicom::Client.new("VOTRE_GLN_REVENDEUR","VOTRE_MOT_DE_PASSE_REVENDEUR")
```

Il est possible d'utiliser le mode TEST en ajoutant un argument true :
```ruby
client=HubDilicom::Client.new("VOTRE_GLN_REVENDEUR_TEST","VOTRE_MOT_DE_PASSE_REVENDEUR_TEST",true)
```

Chaque entitée est représentée par un objet à instancier dont les variables seront remplies par le client.

Par exemple pour un livre :
```ruby
livre=HubDilicom::Book.new("EAN13_DU_LIVRE","GLN_DU_DISTRIBUTEUR")
client.get_book_onix(livre)
livre.onix => message ONIX
client.get_book_availability(livre)
livre.available => bool dispo
```

De la même manière pour une commande :
```ruby
acheteur=HubDilicom::Customer.new("VOTRE_IDENTIFIANT_CLIENT_UNIQUE","Nom du client","Pays","Code postal","Ville")
livre=HubDilicom::Book.new("EAN13_DU_LIVRE","GLN_DU_DISTRIBUTEUR")
ligne_de_commande=HubDilicom::OrderLine.new(livre,1)
commande=HubDilicom::Order.new("VOTRE_IDENTIFIANT_COMMANDE_UNIQUE",[ligne_de_commande])
client.send_order(commande,acheteur)

ligne_commande.links.first.url => URL du fichier
```

En cas de problème, une exception est déclenchée :
```
client.send_order(commande_deja_existante,acheteur)
3025594049409 : Order with referenceCommande 'TESTCOMMANDE' already exists (HubDilicom::OrderDuplicatedError)
```

Pour plus de détails, voir le code source.
