package controller;
import Common;
class Shop extends sugoi.BaseController
{
	
	@tpl('shop/default.mtt')
	public function doDefault() {
		
		view.products = getProducts();
	}
	
	/**
	 * full product list in AJAX
	 */
	public function doProducts() {
		var products = getProducts();
		Sys.print( haxe.Json.stringify( products ) );
	}
	
	/**
	 * récupérer les produits des contrats à commande variable en cours 
	 */
	public function getProducts():Array<ProductInfo> {
		var contracts = db.Contract.getActiveContracts(app.user.amap);
		
		//que les contrats a commande variables
		for (c in Lambda.array(contracts)) {
			if (c.type != db.Contract.TYPE_VARORDER) {
				contracts.remove(c);
			}
		}
		var products = db.Product.manager.search($contractId in Lambda.map(contracts, function(c) return c.id), { orderBy:name }, false);
		
		//retire les produits avec un stock à zero
		for (p in products) {
			if (p.contract.hasStockManagement() && p.stock <= 0) {
				products.remove(p);
			}
			
		}
		
		return Lambda.array(Lambda.map(products, function(p) return p.infos()));
	}
	
	@tpl('shop/productInfo.mtt')
	public function doProductInfo(p:db.Product) {
		view.p = p.infos();
		view.product = p;
		view.vendor = p.contract.vendor;
	}
	
	/**
	 * receive cart
	 */
	public function doSubmit() {
		
		var order : Order = haxe.Json.parse(app.params.get("data"));
		app.session.data.order = order;
		
	}
	
	
	/**
	 * valider la commande et selectionner les distributions
	 */
	@tpl('shop/validate.mtt')
	public function doValidate() {
		//pêche aux datas
		var order : Order = app.session.data.order;
		
		if (order == null || order.products == null || order.products.length == 0) {
			throw Error("/shop", "Vous devez réaliser votre commande avant de valider.");
		}
		
		var pids = Lambda.map(order.products, function(p) return p.productId);
		var products = db.Product.manager.search($id in pids, false);
		var _cids = Lambda.map(products, function(p) return p.contract.id);
		var distribs = db.Distribution.manager.search(($contractId in _cids) && $date >= Date.now(), { orderBy:date }, false);
		
		//dedups cids
		var cids = new Map<Int,Int>();
		for (c in _cids) cids.set(c, c);
		
		//on créé un formulaire
		var form = new sugoi.form.Form("validate");
		form.submitButtonLabel = "Valider la commande";
		for (cid in cids) {
			//liste des produits dans un bloc HTML
			var html = "<ul>";
			for ( p in products) {
				if (p.contract.id == cid) {
					for (o in order.products) {
						if(o.productId==p.id) html += "<li>" + o.quantity +" x " + p.name+ "</li>";
					}
				}
			}
			html += "</ul>";
			form.addElement(new sugoi.form.elements.Html(html,"Produits"));
			
			//liste des distributions possibles en radio group
			var data = new Array<{key:String,value:String}>();
			for (d in distribs) {
				if (d.contract.id == cid) data.push( { key:Std.string(d.id), value:view.hDate(d.date)+" - "+d.place.name } );				
			}
			if (data.length > 0) {
				form.addElement(new sugoi.form.elements.RadioGroup("distrib"+cid,"Livraisons",data,data[0].key));	
			}else {
				form.addElement(new sugoi.form.elements.Html("Aucune livraison n'est prévue pour l'instant.","Livraisons"));
			}
			form.addElement(new sugoi.form.elements.Html("<hr/>"));
			
		}
		
		
		if (form.isValid()) {
			
			//collecte quelle distrib choisie pour quel contrat
			var cd = new Map<Int,Int>();  //contract id -> distrib id
			for (e in form.elements) {
				if (e.name == null) continue;//Html form element has no name
				if (e.name.substr(0, 7) == "distrib") {
					cd.set(Std.parseInt(e.name.substr(7)), Std.parseInt(e.value));
				}
			}
			
			var errors = [];
			
			//créé les commandes
			for (o in order.products) {
				var p = db.Product.manager.get(o.productId,false);
				
				var d = cd.get(p.contract.id);
				if (d == null) {
					//throw "pas trouvé la distribution du produit " + o.productId+" , contrat "+p.contract.name;
					errors.push("Le produit \""+p.name+"\" n'ayant pas de livraison associée, il a été retiré de votre commande");
				}else {
					//enregistre la commande
					db.UserContract.make(app.user,o.quantity, o.productId, d);
				}
			}
			
			if (errors.length > 0) {
				app.session.addMessage(errors.join("<br/>"), true);
				app.logError("params : "+App.current.params.toString()+"\n \n"+errors.join("\n"));
				
			}
			
			app.session.data.order = null;
			throw Ok("/contract", "Votre commande a bien été enregistrée");
		}
		
		
		view.form = form;
	}
	
	
	/**
	 * valider la commande et selectionner les distributions
	 */
	@tpl('shop/validate.mtt')
	public function ___doValidate() {
		
		//pêche aux datas
		var order : Order = app.session.data.order;
		var pids = Lambda.map(order.products, function(p) return p.productId);
		var products = db.Product.manager.search($id in pids, false);
		var cids = Lambda.map(products, function(p) return p.contract.id);
		var distribs = db.Distribution.manager.search($contractId in cids,{orderBy:date,limit:5}, false);
		
		//grouper distribs par date
		var dbd = new Map<String,Array<db.Distribution>>();
		for ( d in distribs) {
			var k = d.date.toString().substr(0, 10);
			if (!dbd.exists(k)) {
				dbd.set(k, [d]);
			}else {
				var v = dbd.get(k);
				v.push(d);
				dbd.set(k, v);
			}
		}
		
		//faire un couple produits - dsitributions possibles
		var out = new Array<{products:Array<{q:Int,p:db.Product}>,distribs : Array<db.Distribution>}>();
		for (k in dbd.keys()) {
			var ps = [];
			for (p in products) {
				//trouve les dsitributions qui correspondent au contrat de ce produit
				var find = Lambda.filter(dbd.get(k), function(d) return d.contract.id == p.contract.id);
				if (find.length > 0) {
					//retrouve la quantité
					var f = Lambda.find(order.products, function(x) return x.productId == p.id);				
					ps.push({q:f.quantity,p:p});
				}
			}
			out.push({products:ps,distribs:dbd.get(k)});
		}
		
		//on créé un formulaire
		var form = new sugoi.form.Form("validate");
		for (o in out) {
			//liste des produits dans un bloc HTML
			var html = "<ul>";
			for ( p in o.products) html += "<li>" + p.q +" x " + p.p.name+ "</li>";
			html += "</ul>";
			form.addElement(new sugoi.form.elements.Html(html));
			
			var data = new Array<{key:String,value:String}>();
			for (d in o.distribs) {
				data.push({key:d.date.toString().substr(0,10),value:d.toString()});
			}
			form.addElement(new sugoi.form.elements.RadioGroup("distrib","Livraisons",data,data[0].key));
		}
		
		view.form = form;
		view.out = out;
		
	}
}