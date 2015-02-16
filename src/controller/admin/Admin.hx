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
	
	@tpl("admin/errors.mtt")
	function doErrors( args:{?user: Int, ?like: String} ) {
		view.now = Date.now();

		view.u = args.user!=null ? db.User.manager.get(args.user,false) : null;
		view.like = args.like!=null ? args.like : "";

		var sql = "";
		if( args.user!=null ) sql += " AND uid="+args.user;
		if( args.like!=null && args.like != "" ) sql += " AND error like "+sys.db.Manager.cnx.quote("%"+args.like+"%");


		var errorsStats = sys.db.Manager.cnx.request("select count(id) as c,date as d,DATE_FORMAT(date,'%d-%b') as day from Error where date > NOW()- INTERVAL 1 MONTH "+sql+" group by day order by d").results();
		view.errorsStats = errorsStats;

		view.browser = new sugoi.tools.ResultsBrowser(
			sugoi.db.Error.manager.unsafeCount("SELECT count(*) FROM Error WHERE 1 "+sql),
			20,
			function(start, limit) {  return sugoi.db.Error.manager.unsafeObjects("SELECT * FROM Error WHERE 1 "+sql+" ORDER BY date DESC LIMIT "+start+","+limit,false); }
		);
	}
	
}
