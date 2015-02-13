package controller.admin;

/**
 * ...
 * @author 
 */
class Marketing extends Controller
{

	public function new() 
	{
		super();	
	}
	
	@tpl("admin/marketing/default.mtt")
	public function doDefault() {
		var users = new Map<Int,db.User>();
		var amaps = db.Amap.manager.all();
		for ( amap in amaps) {
			users.set(amap.contact.id,amap.contact);
			
			for ( c in amap.getActiveContracts()) {
				if(c.contact!=null) users.set(c.contact.id,c.contact);
			}
			
		}
		
		if (app.params.exists("csv")) {
			var uu = Lambda.array(users);
			for (u in uu) Reflect.setProperty(u, "CLIENT", "1");
						
			setCsvData(uu, ["email","firstName", "lastName","CLIENT"],"Clients-cagette");
			return;
		}
		
		
		
		view.users = Lambda.array(users);
		view.amaps = amaps;
	}
	
}