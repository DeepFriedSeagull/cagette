package controller;

class Cron extends Controller
{

	public function doDefault() 
	{
		
	}
	
	/**
	 * CLI only en prod
	 */
	function canRun() {
		if (App.config.DEBUG) {
			
			return true;
		}else {
			
			if (neko.Web.isModNeko) {
				Sys.print("only CLI.");
				return false;
			}else {
				return true;
			}
		}
	}
	
	@tpl("form.mtt")
	public function doMinute() {
		if (!canRun()) return;
		
		alerts(4,db.User.UserFlags.HasEmailNotif4h); //4h avant
		alerts(24,db.User.UserFlags.HasEmailNotif24h); //24h avant
	}
	
	public function doHour() {
		
	}
	
	
	function alerts(hour:Int,flag:db.User.UserFlags) {
		
		//trouve les distrib qui se font dans 4h
		var d = DateTools.delta(Date.now(), 1000 * 60 * 60 * hour); //dans 4h
		var h = DateTools.delta(Date.now(), 1000 * 60 * 60 * (hour+1) ); //dans 5h
		//distribs ayent lieu de dans 4h à dans 5h
		var distribs = db.Distribution.manager.search( $date >= d && $date <=h , false);
		//var distribs = db.Distribution.manager.search( $date > h , false); //TEST
		App.log(distribs);
		
		//cherche plus tard si on a pas une "grappe" de distrib
		while (true) {
			var extraDistribs = db.Distribution.manager.search( $date >= h && $date <DateTools.delta(h,1000.0*60*60) , false);
			App.log("extraDistribs : " + extraDistribs);
			for ( e in extraDistribs) distribs.add(e);
			if (extraDistribs.length > 0) {
				//on fait un tour de plus avec une heure plus tard
				h = DateTools.delta(h, 1000.0 * 60 * 60);
			}else {
				//plus de distribs
				break;
			}
		}
		
		//on vérifie dans le cache du jour que ces distrib n'ont pas deja été traitées lors d'un cron précédent
		var cacheId = Date.now().toString().substr(0, 10)+Std.string(flag);
		var dist :Array<Int> = db.Cache.get(cacheId);
		if (dist != null) {
			for (d in Lambda.array(distribs)) {
				if (Lambda.exists(dist, function(x) return x == d.id)) {
					distribs.remove(d);
				}
			}
		}else {
			dist = [];
		}
		//toutes les distribs trouvées ont deja été traitées
		if (distribs.length == 0) {
			App.log("toutes les distribs trouvées ont deja été traitées");
			return;
		}
		
		//stocke cache
		for (d in distribs) dist.push(d.id);
		db.Cache.set(cacheId, dist,24*60*60);
		
		var distribsByContractId = new Map<Int,db.Distribution>();
		for (d in distribs) distribsByContractId.set(d.contract.id, d);
		
		var contracts = Lambda.map(distribs, function(d) return d.contract);
		var products = [];
		for ( c in contracts) {
			products = products.concat(Lambda.array(c.getProducts()));
		}
		var productsId = products.map(function(p) return p.id);
		
		//chope les commandes liées a cette distrib
		var orders = db.UserContract.manager.search($productId in productsId, false);
		
		//groupe les commande par user 
		var users = new Map< Int,  {user:db.User,distrib:db.Distribution,products:Array<db.UserContract>} >();
		for (o in orders) {
			var x = users.get(o.userId);
			if (x == null) x = {user:o.user,distrib:null,products:[]};
			
			if (o.product.contract.type == db.Contract.TYPE_VARORDER) {
				//commande variable
				if (o.distributionId != distribsByContractId.get(o.product.contract.id).id) {
					//si cette commande ne correspond pas à cette distribution, on passe
					continue;	
				}
			}
			
			x.distrib = distribsByContractId.get(o.product.contract.id);
			x.products.push(o);
			
			users.set(o.userId, x);
		}
		
		
		for ( u in users) {
			
			//trace( u.user.getName() + " a " + u.products + " a la distrib  " + u.distrib );
			
			//que ceux qui ont coché la case
			if (u.user.flags.has(flag) ) {
				
				if (u.user.email != null) {
					var m = new sugoi.mail.MandrillApiMail();
					var group = u.distrib.contract.amap.name;
					m.setSubject( group+" : Distribution à " + u.distrib.date.getHours() + ":" + u.distrib.date.getMinutes() );
					m.setSender("noreply@cagette.net", "Cagette.net");
					m.addRecipient(u.user.email, u.user.getName(), u.user.id);
					if(u.user.email2!=null) m.addRecipient(u.user.email2);
					var text = "N'oubliez pas la distribution : <b>" + view.hDate(u.distrib.date) + "</b><br>";
					text += "Vos produits à récupérer :<br><ul>";
					for ( p in u.products) {
						text += "<li>"+p.quantity+" x "+p.product.name+"</li>";
					}
					text += "</ul>";
					
					if (u.distrib.isDistributor(u.user)) {
						text += "<b>ATTENTION : Vous ou votre conjoint(e) êtes distributeur ! N'oubliez pas d'imprimer la liste d'émargement.</b>";
					}
					
					m.setHtmlBody("mail/message.mtt", { text:text } );
					//App.log("<hr/>"+m.htmlBody+"<hr/>");
					m.send();
					
				}
			}
		}
	}
	
}