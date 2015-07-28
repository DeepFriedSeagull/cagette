package controller;
import db.UserContract;
import sugoi.form.elements.DateDropdowns;
import sugoi.form.elements.Hidden;
import sugoi.form.elements.Input;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;

class Contract extends Controller
{

	public function new() 
	{
		super();
	}
	
	@tpl("contract/view.mtt")
	public function doView(c:db.Contract) {
		view.c = c;
	}
	
	/**
	 * contrats de l'utilisateur en cours
	 */
	@tpl("contract/default.mtt")
	function doDefault() {
		
		var out = new Array< {amap:db.Amap, constOrders:Array<db.UserContract> , varOrders:Map<String,Array<db.UserContract>> } >();
		//for ( a in app.user.getAmaps()) {
		var a = App.current.user.amap;
			
			var row = { amap:a, constOrders:[], varOrders:new Map() };
			
			//commandes fixes
			var contracts = db.Contract.manager.search($type == db.Contract.TYPE_CONSTORDERS && $amap == a && $endDate > Date.now(), false);
			var orders = app.user.getOrdersFromContracts(contracts);
			row.constOrders = Lambda.array(orders);
			
			//commandes variables groupées par date de distrib
			var contracts = db.Contract.manager.search($type == db.Contract.TYPE_VARORDER && $amap == a && $endDate > Date.now(), false);
			var distribs = new Map<String,Array<db.UserContract>>();
			for (c in contracts) {
				var ds = c.getDistribs();
				for (d in ds) {
					var k = d.date.toString().substr(0, 10);
					var orders = app.user.getOrdersFromDistrib(d);
					if (orders.length > 0) {
						if (!distribs.exists(k)) {
							distribs.set(k, Lambda.array(orders));
						}else {
							var z = distribs.get(k).concat(Lambda.array(orders));
							distribs.set(k, z);
						}	
					}
				}
			}
			row.varOrders = distribs;
			
			out.push(row);
		//}
		view.orders = out;
	}

	/**
	 * Modifie un contrat
	 */
	@tpl("form.mtt")
	function doEdit(c:db.Contract) {
		
		if (!app.user.isContractManager(c)) throw Error('/', 'Action interdite');
		
		var currentContact = c.contact;
		var form = Form.fromSpod(c);
		form.removeElement( form.getElement("amapId") );
		form.removeElement(form.getElement("type"));
		form.getElement("userId").required = true;
		
		if (form.checkToken()) {
			
			form.toSpod(c);
			c.amap = app.user.amap;
			
			if (c.hasPercentageOnOrders() && c.percentageValue==null) throw Error("/contract/edit/"+c.id, "Si vous souhaitez ajouter des frais au pourcentage de la commande, spécifiez le pourcentage et son libellé.");
			
			
			
			c.update();
			
			//update rights
			if ( c.contact != null && (currentContact==null || c.contact.id!=currentContact.id) ) {
				var ua = db.UserAmap.get(c.contact, app.user.amap, true);
				ua.giveRight(ContractAdmin(c.id));
				ua.giveRight(Messages);
				ua.giveRight(Membership);
				ua.update();
				
				//remove rights to old contact
				if (currentContact != null) {
					
					var x = db.UserAmap.get(currentContact, c.amap, true);
					if (x == null) throw currentContact+" n'a aucun lien avec "+c.amap.name;
					
					x.removeRight(ContractAdmin(c.id));
					x.update();	
					
				}
				
			}
			
			throw Ok("/contractAdmin/view/"+c.id, "Contrat mis à jour");
		}
		
		view.form = form;
	}
	
	@tpl("contract/insertChoose.mtt")
	function doInsertChoose() {
		//checkToken();
		
	}
	
	/**
	 * Créé un nouveau contrat
	 */
	@tpl("form.mtt")
	function doInsert(?type:Int) {
		if (!app.user.isAmapManager()) throw Error('/', 'Action interdite');
		if (type == null) throw Redirect('/contract/insertChoose');
		
		view.title = if (type == db.Contract.TYPE_CONSTORDERS)"Créer un contrat à commande fixe"else"Créer un contrat à commande variable";
		
		var c = new db.Contract();
		
		var form = Form.fromSpod(c);
		form.removeElement( form.getElement("amapId") );
		form.removeElement(form.getElement("type"));
		form.getElement("userId").required = true;
			
		if (form.checkToken()) {
			form.toSpod(c);
			c.amap = app.user.amap;
			c.type = type;
			c.insert();
			
			//right
			if (c.contact != null) {
				var ua = db.UserAmap.get(c.contact, app.user.amap, true);
				ua.giveRight(ContractAdmin(c.id));
				ua.giveRight(Messages);
				ua.giveRight(Membership);
				ua.update();
			}
			
			throw Ok("/contractAdmin/view/"+c.id, "Nouveau contrat créé");
		}
		
		view.form = form;
	}
	
	function doDelete(c:db.Contract/*,args:{chk:String}*/) {
		
		if (!app.user.isAmapManager()) throw Error("/contractAdmin", "Vous n'avez pas le droit de supprimer un contrat");
		
		if (checkToken()) {
			
			//verif qu'il n'y a pas de commandes sur ce contrat
			var products = c.getProducts();
			var orders = db.UserContract.manager.count($productId in Lambda.map(products, function(p) return p.id));
			if (orders > 0) {
				throw Error("/contractAdmin", "Vous ne pouvez pas effacer ce contrat car il y a des commandes rattachées à ce contrat.");
			}
			
			//remove admin rights and delete contract		
			var ua = db.UserAmap.get(c.contact, c.amap, true);
			if (ua != null) {
				ua.removeRight(ContractAdmin(c.id));
				ua.update();	
			}	
			c.lock();
			c.delete();
			throw Ok("/contractAdmin", "Contrat supprimé");
			
		}
		
		throw Error("/contractAdmin","Erreur de token");
	}
	
	/**
	 * Faire ou modifier une commande 
	 */
	@tpl("contract/order.mtt")
	function doOrder(c:db.Contract,args:{?d:db.Distribution}) {
		if (!c.isUserOrderAvailable()) throw Error("/", "Ce contrat n'est pas ouvert aux commandes ");
		if (c.type == db.Contract.TYPE_VARORDER && args.d == null ) {
			throw Error("/", "Ce contrat est à commande variable, vous devez sélectionner une date de distribution pour faire votre commande.");
		}
		view.c = view.contract = c;
		if (c.type == db.Contract.TYPE_VARORDER) {
			view.distribution = args.d;
		}else {
			view.distributions = c.getDistribs(false);
		}
		
		var userOrders = new Array<{order:db.UserContract,product:db.Product}>();
		var products = c.getProducts();
		
		for ( p in products) {
			var ua = { order:null, product:p };
			
			var order : db.UserContract = null;
			if (c.type == db.Contract.TYPE_VARORDER) {
				order = db.UserContract.manager.select($user == app.user && $productId == p.id && $distributionId==args.d.id, true);	
			}else {
				order = db.UserContract.manager.select($user == app.user && $productId == p.id, true);
			}
			
			if (order != null) ua.order = order;
			userOrders.push(ua);
		}
		
		//form check
		if (checkToken()) {
			
			//get dsitrib if needed
			var distrib : db.Distribution = null;
			if (c.type == db.Contract.TYPE_VARORDER) {
				distrib = db.Distribution.manager.get(Std.parseInt(app.params.get("distribution")), false);
			}
			
			for (k in app.params.keys()) {
				var param = app.params.get(k);
				if (k.substr(0, "product".length) == "product") {
					
					//trouve le produit dans userOrders
					var pid = Std.parseInt(k.substr("product".length));
					var uo = Lambda.find(userOrders, function(uo) return uo.product.id == pid);
					if (uo == null) throw "Impossible de retrouver le produit " + pid;
					var q = Std.parseInt(param);
					
					var order = new db.UserContract();
					if (uo.order != null) {
						//record existant
						order = uo.order;
						if (q == 0) {
							order.lock();
							order.delete();
						}else {
							order.lock();
							order.paid = (q==order.quantity && order.paid); //si deja payé et quantité inchangée
							order.quantity = q;						
							order.update();	
						}
					}else {
						//nouveau record
						if (q != 0) {
							order.user = app.user;
							order.product = uo.product;
							order.quantity = q;
							order.paid = false;
							order.amap = app.user.amap;
							order.distribution = distrib;
							order.insert();	
						}
					}
				}
			}
			if (distrib != null) {
				throw Ok("/contract/order/" + c.id+"?d="+distrib.id, "Votre commande a été mise à jour");	
			}else {
				throw Ok("/contract/order/" + c.id, "Votre commande a été mise à jour");	
			}
			
		}
		
		view.userOrders = userOrders;
		
	}
	
	/**
	 * Modifier une commande en fonction du jour de livraison (tout fournisseurs confondus)
	 */
	@tpl("contract/orderByDate.mtt")
	function doEditOrderByDate(date:Date) {
		
		
		//comment on sait si on peut encore modifier la commande ?
		// Il faut regarder le contrat de chaque produit et verifier si le contrat est toujours ouvert à la commande.
		
		
		
		//if (!c.isUserOrderAvailable()) throw Error("/", "Ce contrat n'est pas ouvert aux commandes ");
		/*if (c.type == db.Contract.TYPE_VARORDER && args.d == null ) {
			throw Error("/", "Ce contrat est à commande variable, vous devez sélectionner une date de distribution pour faire votre commande.");
		}
		view.c = view.contract = c;
		if (c.type == db.Contract.TYPE_VARORDER) {
			view.distribution = args.d;
		}else {
			view.distributions = c.getDistribs(false);
		}
		
		var userOrders = new Array<{order:db.UserContract,product:db.Product}>();
		var products = c.getProducts();
		
		for ( p in products) {
			var ua = { order:null, product:p };
			
			var order : db.UserContract = null;
			if (c.type == db.Contract.TYPE_VARORDER) {
				order = db.UserContract.manager.select($user == app.user && $productId == p.id && $distributionId==args.d.id, true);	
			}else {
				order = db.UserContract.manager.select($user == app.user && $productId == p.id, true);
			}
			
			if (order != null) ua.order = order;
			userOrders.push(ua);
		}
		
		//form check
		if (checkToken()) {
			
			//get dsitrib if needed
			var distrib : db.Distribution = null;
			if (c.type == db.Contract.TYPE_VARORDER) {
				distrib = db.Distribution.manager.get(Std.parseInt(app.params.get("distribution")), false);
			}
			
			for (k in app.params.keys()) {
				var param = app.params.get(k);
				if (k.substr(0, "product".length) == "product") {
					
					//trouve le produit dans userOrders
					var pid = Std.parseInt(k.substr("product".length));
					var uo = Lambda.find(userOrders, function(uo) return uo.product.id == pid);
					if (uo == null) throw "Impossible de retrouver le produit " + pid;
					var q = Std.parseInt(param);
					
					var order = new db.UserContract();
					if (uo.order != null) {
						//record existant
						order = uo.order;
						if (q == 0) {
							order.lock();
							order.delete();
						}else {
							order.lock();
							order.paid = (q==order.quantity && order.paid); //si deja payé et quantité inchangée
							order.quantity = q;						
							order.update();	
						}
					}else {
						//nouveau record
						if (q != 0) {
							order.user = app.user;
							order.product = uo.product;
							order.quantity = q;
							order.paid = false;
							order.amap = app.user.amap;
							order.distribution = distrib;
							order.insert();	
						}
					}
				}
			}
			if (distrib != null) {
				throw Ok("/contract/order/" + c.id+"?d="+distrib.id, "Votre commande a été mise à jour");	
			}else {
				throw Ok("/contract/order/" + c.id, "Votre commande a été mise à jour");	
			}
			
		}
		
		view.userOrders = userOrders;*/
		
	}
	
	
}