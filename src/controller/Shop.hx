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
		for (c in Lambda.array(contracts)) {
			if (c.type != db.Contract.TYPE_VARORDER) {
				contracts.remove(c);
			}
		}
		var products = db.Product.manager.search($contractId in Lambda.map(contracts, function(c) return c.id), false);
		return Lambda.array(Lambda.map(products, function(p) return p.infos()));
	}
	
	@tpl('shop/productInfo.mtt')
	public function doProductInfo(p:db.Product) {
		view.p = p.infos();
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
		var order : Order = app.session.data.order;
		var pids = Lambda.map(order.products, function(p) return p.productId);
		var products = db.Product.manager.search($id in pids, false);
		var cids = Lambda.map(products, function(p) return p.contract.id);
		var distribs = db.Distribution.manager.search($contractId in cids, false);
		
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
		var out = new Array<{products:Array<db.Product>,distribs : Array<db.Distribution>}>();
		for (k in dbd.keys()) {
			var ps = [];
			for (p in products) {
				//trouve les dsitributions qui correspondent au contrat de ce produit
				var find = Lambda.filter(dbd.get(k), function(d) return d.contract.id == p.contract.id);
				if (find.length > 0) {
					ps.push(p);
				}
			}
			out.push({products:ps,distribs:dbd.get(k)});
		}
		
		
		
		view.out = out;
		
	}
}