package controller;
import sugoi.form.Form;

class Distribution extends Controller
{

	public function new()
	{
		super();
		
	}
	
	/**
	 * Liste d'émargement
	 */
	@tpl('distribution/list.mtt')
	function doList(d:db.Distribution) {
		view.distrib = d;
		var contract = d.contract;
		view.contract = d.contract;
		view.contracts = d.getOrders();
	}
	
	/**
	 * Liste d'émargement globale pour une date donnée (multi fournisseur)
	 */
	@tpl('distribution/listByDate.mtt')
	function doListByDate(?date:Date,?onePage:Bool) {
		
		if (date == null) {
		
			var f = new sugoi.form.Form("listBydate", null, sugoi.form.Form.FormMethod.GET);
			f.addElement(new sugoi.form.elements.DatePicker("date", "Date de livraison", true));
			f.addElement(new sugoi.form.elements.RadioGroup("page", "Affichage", [ { key:"onePage", value:"Une personne par page" }, { key:"all", value:"Tout à la suite" } ]));
			
			view.form = f;
			app.setTemplate("form.mtt");
			
			if (f.checkToken()) {
				
				var url = '/distribution/listByDate/' + f.getValueOf("date").toString().substr(0, 10);
				
				if (f.getValueOf("page") == "onePage") {
					url += "/1";
				}
				
				throw Redirect( url );
			}
			
			return;
			
		}else {
			view.date = date;
			
			if (onePage) {
				app.setTemplate("distribution/listByDateOnePage.mtt");
			}
			
			var d1 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
			var d2 = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59);
			var contracts = app.user.amap.getActiveContracts(true);
			var cids = Lambda.map(contracts, function(c) return c.id);
			var cconst = [];
			var cvar = [];
			for ( c in contracts) {
				if (c.type == db.Contract.TYPE_CONSTORDERS) cconst.push(c.id);
				if (c.type == db.Contract.TYPE_VARORDER) cvar.push(c.id);
			}
			
			//commandes variables
			var distribs = db.Distribution.manager.search(($contractId in cvar) && $date >= d1 && $date <= d2 , false);		
			var orders = db.UserContract.manager.search($distributionId in Lambda.map(distribs, function(d) return d.id)  , { orderBy:userId } );
			
			//commandes fixes
			var distribs = db.Distribution.manager.search(($contractId in cconst) && $date >= d1 && $date <= d2 , false);	
			var products = [];
			for ( d in distribs) {
				for ( p in d.contract.getProducts()) {
					products.push(p);
				}
			}
			var orders2 = db.UserContract.manager.search($productId in Lambda.map(products, function(d) return d.id)  , { orderBy:userId } );
			
			var orders = Lambda.array(orders).concat(Lambda.array(orders2));
			
			view.orders = db.UserContract.prepare(Lambda.list(orders));
		}
		
	}
	
	
	
	function doDelete(d:db.Distribution) {
		
		if (!app.user.canManageContract(d.contract)) throw "action non autorisée";		
		if (db.UserContract.manager.search($distributionId == d.id, false).length > 0) throw Error("/contractAdmin/distributions/" + d.contract.id, "Effacement impossible : Des commandes sont enregistrées pour cette distribution.");
		
		d.lock();
		var cid = d.contract.id;
		d.delete();
		throw Ok("/contractAdmin/distributions/" + cid, "la distribution a bien été effacée");
	}
	
	/**
	 * Edit a delivery
	 */
	@tpl('form.mtt')
	function doEdit(d:db.Distribution) {
		
		if (!app.user.canManageContract(d.contract)) throw "action non autorisée";
		
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("end"));
		form.removeElement(form.getElement("distributionCycleId"));
		var x = new sugoi.form.elements.HourDropDowns("end", "heure de fin",d.end,true);
		form.addElement(x, 4);
		
		if (d.contract.type == db.Contract.TYPE_VARORDER ) {
			form.addElement(new sugoi.form.elements.DatePicker("orderStartDate", App.t._("orderStartDate"), d.orderStartDate));	
			form.addElement(new sugoi.form.elements.DatePicker("orderEndDate", App.t._("orderEndDate"), d.orderEndDate));
		}
		
		if (form.isValid()) {
			form.toSpod(d); //update model
			
			if (d.contract.type == db.Contract.TYPE_VARORDER ) checkDistrib(d);
			
			//var days = Math.floor( d.date.getTime() / 1000 / 60 / 60 / 24 );
			d.end = new Date(d.date.getFullYear(), d.date.getMonth(), d.date.getDate(), d.end.getHours(), d.end.getMinutes(), 0);
			d.update();
			throw Ok('/contractAdmin/distributions/'+d.contract.id,'La distribution a été mise à jour');
		}
		
		view.form = form;
		view.title = "Modifier une livraison";
	}
	
	@tpl('form.mtt')
	function doEditCycle(d:db.DistributionCycle) {
		
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		
		if (form.isValid()) {
			form.toSpod(d); //update model
			d.update();
			throw Ok('/contractAdmin/distributions/'+d.contract.id,'La distribution a été mise à jour');
		}
		
		view.form = form;
		view.title = "Modifier une distribution";
	}
	
	@tpl("form.mtt")
	public function doInsert(contract:db.Contract) {
		
		var d = new db.Distribution();
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("distributionCycleId"));
		form.removeElement(form.getElement("end"));
		var x = new sugoi.form.elements.HourDropDowns("end", "heure de fin");
		form.addElement(x, 4);
		
		if (contract.type == db.Contract.TYPE_VARORDER ) {
			form.addElement(new sugoi.form.elements.DatePicker("orderStartDate", App.t._("orderStartDate")));	
			form.addElement(new sugoi.form.elements.DatePicker("orderEndDate", App.t._("orderEndDate")));
		}
		
		if (form.isValid()) {
			
			form.toSpod(d); //update model
			d.contract = contract;			
			var days = Math.floor( d.date.getTime() / 1000 / 60 / 60 / 24 );			
			if (d.end == null) d.end = DateTools.delta(d.date, 1000.0 * 60 * 60);
			d.end = new Date(d.date.getFullYear(), d.date.getMonth(), d.date.getDate(), d.end.getHours(), d.end.getMinutes(), 0);
			
			if (contract.type == db.Contract.TYPE_VARORDER ) checkDistrib(d);
			d.insert();
			throw Ok('/contractAdmin/distributions/'+d.contract.id,'La distribution a été enregistrée');
		}
	
		view.form = form;
		view.title = "Programmer une nouvelle distribution";
	}
	
	/**
	 * checks if dates are correct
	 * @param	d
	 */
	function checkDistrib(d:db.Distribution) {
		
		if (d.date.getTime() < d.orderEndDate.getTime() ) throw Error('/contractAdmin/distributions/' + d.contract.id, "La date de livraison doit être postérieure à la date de fermeture des commandes");
		if (d.date.getTime() < d.orderStartDate.getTime() ) throw Error('/contractAdmin/distributions/' + d.contract.id, "La date de livraison doit être postérieure à la date d'ouverture des commandes");
		if (d.orderStartDate.getTime() > d.orderEndDate.getTime() ) throw Error('/contractAdmin/distributions/' + d.contract.id, "La date de fermeture des commandes doit être postérieure à la date d'ouverture des commandes !");
		
		
	}
	
	@tpl("form.mtt")
	public function doInsertCycle(contract:db.Contract) {
		
		var d = new db.DistributionCycle();
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("startHour"));
		var x = new sugoi.form.elements.HourDropDowns("startHour", "Heure de début",d.startHour,true);
		form.addElement(x, 5);
		form.removeElement(form.getElement("endHour"));
		var x = new sugoi.form.elements.HourDropDowns("endHour", "Heure de fin",d.endHour,true);
		form.addElement(x, 6);
		
		if (form.isValid()) {
			
			
			form.toSpod(d); //update model
			d.contract = contract;
			d.insert();
			db.DistributionCycle.updateChilds(d);
			throw Ok('/contractAdmin/distributions/'+d.contract.id,'La distribution a été enregistrée');
		}
		
		view.form = form;
		view.title = "Programmer une distribution récurrente";
	}
	
	/**
	 * Doodle like
	 */
	@tpl("distribution/planning.mtt")
	public function doPlanning(contract:db.Contract) {
	
		view.contract = contract;

		var doodle = new Map<Int,{user:db.User,planning:Map<Int,Bool>}>();
		var distribs = contract.getDistribs(true, 150);
		
		for ( d in distribs ) {
			for (u in [d.distributor1, d.distributor2, d.distributor3, d.distributor4]) {
				if (u != null) {
					
					var udoodle = doodle.get(u.id);
					
					if (udoodle == null) udoodle = { user:u, planning:new Map<Int,Bool>() };
					udoodle.planning.set(d.id, true);
					doodle.set(u.id, udoodle);
					
				}
			}
			
		}
		view.distribs = distribs;
		view.doodle = doodle;
		
	}
	
	/**
	 * ajax pour doodle/planning
	 */
	public function doRegister(args: { register:Bool, distrib:db.Distribution } ) {
		
		if (args != null) {
			var d = args.distrib;
			d.lock();
			
			if (args.register) {
				
				if (d.distributor1 == null) d.distributor1 = app.user;
				else if (d.distributor2 == null) d.distributor2 = app.user;
				else if (d.distributor3 == null) d.distributor3 = app.user;
				else if (d.distributor4 == null) d.distributor4 = app.user;
				
			}else {
				if (d.distributor1 == app.user) d.distributor1 = null;
				else if (d.distributor2 == app.user) d.distributor2 = null;
				else if (d.distributor3 == app.user) d.distributor3 = null;
				else if (d.distributor4 == app.user) d.distributor4 = null;
			}
			
			
			d.update();
		}
		
	}
	
}