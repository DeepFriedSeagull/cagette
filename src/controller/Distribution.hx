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
	
	function doDelete(d:db.Distribution) {
		
		if (!app.user.canManageContract(d.contract)) throw "action non autorisée";
		
		if (db.UserContract.manager.search($distributionId == d.id, false).length > 0) throw Error("/contractAdmin/distributions/" + d.contract.id, "Effacement impossible : Des commandes sont enregistrées pour cette distribution.");
		
		d.lock();
		var cid = d.contract.id;
		d.delete();
		throw Ok("/contractAdmin/distributions/" + cid, "la distribution a bien été effacée");
		
		
	}
	
	
	@tpl('form.mtt')
	function doEdit(d:db.Distribution) {
		
		if (!app.user.canManageContract(d.contract)) throw "action non autorisée";
		
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("end"));
		form.removeElement(form.getElement("distributionCycleId"));
		var x = new sugoi.form.elements.HourDropDowns("end", "heure de fin",d.end);
		form.addElement(x, 4);
		
		if (form.isValid()) {
			form.toSpod(d); //update model
			//var days = Math.floor( d.date.getTime() / 1000 / 60 / 60 / 24 );
			d.end = new Date(d.date.getFullYear(), d.date.getMonth(), d.date.getDate(), d.end.getHours(), d.end.getMinutes(), 0);
			d.update();
			throw Ok('/contractAdmin/distributions/'+d.contract.id,'La distribution a été mise à jour');
		}
		
		view.form = form;
		view.title = "Modifier une distribution";
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
		form.addElement(x,4);
		
		if (form.isValid()) {
			form.toSpod(d); //update model
			d.contract = contract;
			var days = Math.floor( d.date.getTime() / 1000 / 60 / 60 / 24 );
			d.end = new Date(d.date.getFullYear(), d.date.getMonth(), d.date.getDate(), d.end.getHours(), d.end.getMinutes(), 0);
			d.insert();
			//Weblog.debug(d);
			throw Ok('/contractAdmin/distributions/'+d.contract.id,'La distribution a été enregistrée');
		}
	
		view.form = form;
		view.title = "Programmer une nouvelle distribution";
	}
	
	@tpl("form.mtt")
	public function doInsertCycle(contract:db.Contract) {
		
		var d = new db.DistributionCycle();
		var form = sugoi.form.Form.fromSpod(d);
		form.removeElement(form.getElement("contractId"));
		form.removeElement(form.getElement("startHour"));
		var x = new sugoi.form.elements.HourDropDowns("startHour", "Heure de début",d.startHour);
		form.addElement(x, 5);
		form.removeElement(form.getElement("endHour"));
		var x = new sugoi.form.elements.HourDropDowns("endHour", "Heure de fin",d.endHour);
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
		
		for ( d in contract.getDistribs() ) {
			for (u in [d.distributor1, d.distributor2, d.distributor3, d.distributor4]) {
				if (u != null) {
					
					var udoodle = doodle.get(u.id);
					
					if (udoodle == null) udoodle = { user:u, planning:new Map<Int,Bool>() };
					udoodle.planning.set(d.id, true);
					doodle.set(u.id, udoodle);
					
				}
			}
			
		}
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