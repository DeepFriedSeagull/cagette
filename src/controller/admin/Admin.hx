package controller.admin;
import haxe.web.Dispatch;
import Common;

class Admin extends Controller {
	
	public function new() {
		super();
		view.category = 'admin';
		
		//lance un event pour demander aux plugins si ils veulent ajouter un item dans la nav
		var nav = new Array<Link>();
		var e = new event.NavEvent();
		e.id = "admin";
		App.current.eventDispatcher.dispatch(e);
		view.nav = e.nav;
		
	}

	@tpl("admin/default.mtt")
	function doDefault() {
		
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
	
	function doPlugins(d:Dispatch) {
		d.dispatch(new controller.admin.Plugins());
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

