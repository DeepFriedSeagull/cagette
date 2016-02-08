package controller;
import db.UserContract;
import sugoi.form.Form;

class Amap extends Controller
{

	public function new() 
	{
		super();
	}
	
	@tpl("amap/default.mtt")
	function doDefault() {
		var contracts = db.Contract.getActiveContracts(app.user.amap, true, false);
		for ( c in Lambda.array(contracts).copy()) {
			if (c.endDate.getTime() < Date.now().getTime() ) contracts.remove(c);
		}
		view.contracts = contracts;
	}
	
	
	@tpl("form.mtt")
	function doEdit() {
		
		if (!app.user.isAmapManager()) throw "Vous n'avez pas accès a cette section";
		
		var form = Form.fromSpod(app.user.amap);
	
		if (form.checkToken()) {
			form.toSpod(app.user.amap);
			app.user.amap.update();
			throw Ok("/amapadmin", "Groupe mis à jour.");
		}
		
		view.form = form;
	}
	
}