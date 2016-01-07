package controller;
import db.UserContract;
import sugoi.form.elements.DateDropdowns;
import sugoi.form.elements.Hidden;
import sugoi.form.elements.Input;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;
import db.Contract;
using Std;

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
		
		var constOrders = null;
		var varOrders = new Map<String,Array<db.UserContract>>();
		
		var a = App.current.user.amap;		
		var oneMonthAgo = DateTools.delta(Date.now(), -1000.0 * 60 * 60 * 24 * 30);
		
		//commandes fixes
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_CONSTORDERS && $amap == a && $endDate > oneMonthAgo, false);
		constOrders = db.UserContract.prepare(app.user.getOrdersFromContracts(contracts));
		
		//commandes variables groupées par date de distrib
		var contracts = db.Contract.manager.search($type == db.Contract.TYPE_VARORDER && $amap == a && $endDate > oneMonthAgo, false);
		
		for (c in contracts) {
			var ds = c.getDistribs(false);
			for (d in ds) {
				//store orders in a stringmap like "2015-01-01" => [order1,order2,...]
				var k = d.date.toString().substr(0, 10);
				var orders = app.user.getOrdersFromDistrib(d);
				if (orders.length > 0) {
					if (!varOrders.exists(k)) {
						varOrders.set(k, Lambda.array(orders));
					}else {
						var z = varOrders.get(k).concat(Lambda.array(orders));
						varOrders.set(k, z);
					}	
				}
			}
		}
		
		//struct finale
		var varOrders2 = new Array<{date:Date,orders:Array<db.UserContract>}>();
		for ( k in varOrders.keys()) {
			var d = new Date(k.split("-")[0].parseInt(), k.split("-")[1].parseInt()-1, k.split("-")[2].parseInt(), 0, 0, 0);
			varOrders2.push({date:d,orders:varOrders[k]});
			
		}
		
		
		//trier la map par ordre chrono desc
		
		
		varOrders2.sort(function(b, a) {
			return Math.round(a.date.getTime()/1000)-Math.round(b.date.getTime()/1000);
		});
		
		
		view.varOrders = varOrders2;
		view.constOrders = constOrders;
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
			
			//checks & warnings
			if (c.hasPercentageOnOrders() && c.percentageValue==null) throw Error("/contract/edit/"+c.id, "Si vous souhaitez ajouter des frais au pourcentage de la commande, spécifiez le pourcentage et son libellé.");
			
			if (c.hasStockManagement()) {
				for (p in c.getProducts()) {
					if (p.stock == null) {
						app.session.addMessage("Attention, vous avez activé la gestion des stocks. Pensez à renseigner le champs \"stock\" de tout vos produits", true);
						break;
					}
				}
			}
			
			//no stock mgmt for constant orders
			if (c.hasStockManagement() && c.type==db.Contract.TYPE_CONSTORDERS) {
				c.flags.unset(ContractFlags.StockManagement);
				app.session.addMessage("La gestion des stocks n'est pas disponible pour les contrats de type AMAP", true);
			}
			
			
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
					if (x != null) {
						x.removeRight(ContractAdmin(c.id));
						x.update();						
					}
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
	function doOrder(c:db.Contract, args: { ?d:db.Distribution } ) {
		
		//checks
		if (app.user.amap.hasShopMode()) throw Redirect("/shop");
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
					
					//var order = new db.UserContract();
					if (uo.order != null) {
						//record existant
						//order = uo.order;
						//if (q == 0) {
							//order.lock();
							//order.delete();
						//}else {
							//order.lock();
							//order.paid = (q==order.quantity && order.paid); //si deja payé et quantité inchangée
							//order.quantity = q;						
							//order.update();	
						//}
						db.UserContract.edit(uo.order, q);
						
						
					}else {
						////nouveau record
						//if (q != 0) {
							//order.user = app.user;
							//order.product = uo.product;
							//order.quantity = q;
							//order.paid = false;
							//order.distribution = distrib;
							//order.insert();	
						//}
						db.UserContract.make(app.user, q, uo.product.id, distrib!=null ? distrib.id : null);
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
		// la date de livraison doit etre dans le futur
		if (Date.now().getTime() > date.getTime()) {
			
			var msg = "Cette livraison a déjà eu lieu, vous ne pouvez plus modifier la commande.";
			if (app.user.isContractManager()) msg += "<br/>En tant que gestionnaire de contrat vous pouvez modifier une commande depuis la page de gestion des commandes dans <a href='/contractAdmin'>Gestion contrats</a> ";
			
			throw Error("/contract", msg);
		}
		
		// Il faut regarder le contrat de chaque produit et verifier si le contrat est toujours ouvert à la commande.		
		var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
		var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
				
		var cids = Lambda.map(app.user.amap.getActiveContracts(true), function(c) return c.id);
		var distribs = db.Distribution.manager.search(($contractId in cids) && $date >= d1 && $date <=d2 , false);
		var orders = db.UserContract.manager.search($userId==app.user.id && $distributionId in Lambda.map(distribs,function(d)return d.id)  );
		view.orders = db.UserContract.prepare(orders);
		view.date = date;
		
		//form check
		if (checkToken()) {
			
			for (k in app.params.keys()) {
				var param = app.params.get(k);
				if (k.substr(0, "product".length) == "product") {
					
					//trouve le produit dans userOrders
					var pid = Std.parseInt(k.substr("product".length));
					var order = Lambda.find(orders, function(uo) return uo.product.id == pid);
					if (order == null) throw "Erreur, impossible de retrouver la commande";
					
					var q = Std.parseInt(param);
					var quantity = Std.int(Math.abs( q==null?0:q ));

					if (!order.paid && order.product.contract.isUserOrderAvailable()) {
						//met a jour la commande
						db.UserContract.edit(order, quantity);
					}
					
				}
			}
			
			throw Ok("/contract", "Votre commande a été mise à jour");	
			
		}
	}
}