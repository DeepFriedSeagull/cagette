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
}