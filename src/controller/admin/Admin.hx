package controller.admin;
import haxe.web.Dispatch;
class Admin extends Controller {

	@tpl("admin/default.mtt")
	function doDefault() {
		view.category = 'admin';
		
	}
	
	function doMigrate() {
		
		//fix contrat miel
		
		//var c = db.Contract.manager.get(90);
		//var pids = Lambda.map(c.getProducts(), function(p) return p.id);
		//var d = db.Distribution.manager.get(900);
		//for ( o in db.UserContract.manager.search($productId in pids, true)) {
			//o.distribvaution  = d;
			//o.update();
			//trace(o.user.getName()+" a commandé "+o.product);
		//}
	}
	
	@tpl("form.mtt")
	function doCreateAccount() {
		
		var f = new sugoi.form.Form("c");
		f.addElement(new sugoi.form.elements.Input("amapName", "Nom de l'Amap"));
		f.addElement(new sugoi.form.elements.Input("userFirstName", "Prenom du compte"));
		f.addElement(new sugoi.form.elements.Input("userLastName", "Nom du compte"));
		f.addElement(new sugoi.form.elements.Input("userEmail", "Email du compte"));
		
		if (f.checkToken()) {
			
			var user = new db.User();
			user.email = f.getValueOf("userEmail");
			user.firstName = f.getValueOf("userFirstName");
			user.lastName = f.getValueOf("userLastName");
			user.pass = "859738d2fed6a98902defb00263f0d35";
			user.insert();
			
			var amap = new db.Amap();
			amap.name = f.getValueOf("amapName");
			amap.contact = user;
			amap.insert();
			
			var ua = new db.UserAmap();
			ua.user = user;
			ua.amap = amap;
			ua.rights = [db.UserAmap.Right.AmapAdmin,db.UserAmap.Right.Membership,db.UserAmap.Right.Messages,db.UserAmap.Right.ContractAdmin(null)];
			ua.insert();
			
			//example datas
			var place = new db.Place();
			place.name = "Place du marché";
			place.amap = amap;
			place.insert();
			
			var vendor = new db.Vendor();
			vendor.amap = amap;
			vendor.name = "Jean Martin EURL";
			vendor.insert();
			
			var contract = new db.Contract();
			contract.name = "Contrat Maraîcher Exemple";
			contract.amap  = amap;
			contract.type = 0;
			contract.vendor = vendor;
			contract.startDate = Date.now();
			contract.endDate = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 364);
			contract.contact = user;
			contract.distributorNum = 2;
			contract.insert();
			
			var p = new db.Product();
			p.name = "Gros panier de légumes";
			p.price = 15;
			p.contract = contract;
			p.insert();
			
			var p = new db.Product();
			p.name = "Petit panier de légumes";
			p.price = 10;
			p.contract = contract;
			p.insert();
		
			var uc = new db.UserContract();
			uc.user = user;
			uc.product = p;
			uc.amap = amap;
			uc.paid = true;
			uc.quantity = 1;
			uc.insert();
			
			var d = new db.Distribution();
			d.contract = contract;
			d.date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
			d.end = DateTools.delta(d.date, 1000.0 * 60 * 90);
			d.place = place;
			d.insert();
			
			throw Ok("/admin", "Amap créée");
			
			
		}
		
		view.form= f;
		
	}
	
	function doMarketing(d: haxe.web.Dispatch) {
		d.dispatch(new controller.admin.Marketing());
	}
	
	//@tpl('admin/mailchimp.mtt')
	function doMailchimp() {
		
		var m = new sugoi.apis.mailchimp.Mailchimp("abaa8eb2949c6114866bd0616c72322b-us6", "1d5c9ae78f", "us6");
		
		var users = new Map<Int,db.User>();
		var amaps = db.Amap.manager.all();
		for ( amap in amaps) {
			users.set(amap.contact.id,amap.contact);
			
			for ( c in amap.getActiveContracts()) {
				if(c.contact!=null) users.set(c.contact.id,c.contact);
			}
			
		}
		
		for (u in users) Sys.println(u.name+"<br>");
		
		/*for (u in users) {
			Sys.sleep(1);
			Sys.print ( m.subscribe("1d5c9ae78f", { email:u.email }, { FNAME:u.firstName, LNAME:u.lastName, mc_language:"fr" },{CLIENT:"1"}, false, true, false) );
		}*/
		
		
	}
	
	@tpl("admin/errors.mtt")
	function doErrors( args:{?user: Int, ?like: String, ?empty:Bool} ) {
		view.now = Date.now();

		view.u = args.user!=null ? db.User.manager.get(args.user,false) : null;
		view.like = args.like!=null ? args.like : "";

		var sql = "";
		if( args.user!=null ) sql += " AND uid="+args.user;
		if( args.like!=null && args.like != "" ) sql += " AND error like "+sys.db.Manager.cnx.quote("%"+args.like+"%");
		if (args.empty) {
					sys.db.Manager.cnx.request("truncate table Error");
				}


		var errorsStats = sys.db.Manager.cnx.request("select count(id) as c,date as d,DATE_FORMAT(date,'%d-%b') as day from Error where date > NOW()- INTERVAL 1 MONTH "+sql+" group by day order by d").results();
		view.errorsStats = errorsStats;

		view.browser = new sugoi.tools.ResultsBrowser(
			sugoi.db.Error.manager.unsafeCount("SELECT count(*) FROM Error WHERE 1 "+sql),
			20,
			function(start, limit) {  return sugoi.db.Error.manager.unsafeObjects("SELECT * FROM Error WHERE 1 "+sql+" ORDER BY date DESC LIMIT "+start+","+limit,false); }
		);
	}
	
}
