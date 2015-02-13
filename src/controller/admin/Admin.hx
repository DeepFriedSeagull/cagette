package controller.admin;
import haxe.web.Dispatch;
class Admin extends Controller {

	@tpl("admin/default.mtt")
	function doDefault() {
		view.category = 'admin';
		
	}
	
	function doMigrate() {
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
	
}
