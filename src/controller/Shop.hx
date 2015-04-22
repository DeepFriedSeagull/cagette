package controller;

class Shop extends sugoi.BaseController
{

	
	
	@tpl('shop/default.mtt')
	public function doDefault() {
		var contracts = db.Contract.getActiveContracts(app.user.amap);
		var products = db.Product.manager.search($contractId in Lambda.map(contracts,function(c) return c.id), false);
		view.products = products;
	}
}