package controller;
import db.UserAmap;
import sugoi.form.Form;
import Types;


class AmapAdmin extends Controller
{

	public function new() 
	{
		super();
		if (!app.user.isAmapManager()) throw Error("/", "Accès non autorisé");
		
		//lance un event pour demander aux plugins si ils veulent ajouter un item dans la nav
		var nav = new Array<Link>();
		var e = new event.NavEvent();
		e.navId = "amapadmin";
		App.eventDispatcher.dispatch(e);
		view.nav = e.nav;
	}
	
	
	@tpl("amapadmin/default.mtt")
	function doDefault() {
		view.membersNum = UserAmap.manager.count($amap == app.user.amap);
		view.contractsNum = app.user.amap.getActiveContracts().length;
		view.aboOk = app.user.amap.isAboOk(); 
	}
	
	
	
	@tpl("amapadmin/rights.mtt")
	public function doRights() {
		
		//liste les gens qui ont des droits dans le groupe
		var users = db.UserAmap.manager.search($rights != null && $amap == app.user.amap, false);
		
		//cleaning 
		for ( u in Lambda.array(users)) {
			
			//rights peut etre null (null seralisé) et pas null en DB
			if (u.rights == null || u.rights.length == 0) {
				u.lock();
				Reflect.setField(u, "rights", null);
				u.update();
				users.remove(u);
				continue;
			}
			
			//droits sur un contrat effacé
			for ( r in u.rights) {
				switch(r) {
					case ContractAdmin(cid):
						if (cid == null) continue;
						var c = db.Contract.manager.get(cid);
						if (c == null) {
							u.lock();
							u.removeRight(r);
							u.update();
						}
					default :
				}
			}
		}
		
		view.users = users;

	}
	
	@admin
	public function doMigrateRights() {
		var users = new Map<Int,db.User>();
		var amaps = db.Amap.manager.all();
		for ( amap in amaps) {
			for ( c in amap.getActiveContracts()) {
				if (c.contact != null) {
					var ua = db.UserAmap.get(c.contact, amap, true);
					ua.giveRight(ContractAdmin(c.id));
					ua.giveRight(Messages);
					ua.giveRight(Membership);
					ua.update();
				}
			}
			
		}
		
		for ( a in amaps) {
			var ua = db.UserAmap.get(a.contact, a, true);
			ua.rights = [AmapAdmin, Messages, ContractAdmin(), Membership];
			ua.update();
		}
		
		//for ( u in users) {
			//var ua = db.UserAmap.get(a.contact, a, true);
		//}
		
		
	}
	
	@tpl("form.mtt")
	public function doEditRight(?u:db.User) {
		
		var form = new sugoi.form.Form("editRight");
		
		if (u == null) {
			form.addElement( new sugoi.form.elements.Selectbox("user", "Adhérent", app.user.amap.getMembersFormElementData(), null, true) );	
		}
		
		var data = [];
		for (r in db.UserAmap.Right.getConstructors()) {
			if (r == "ContractAdmin") continue; //managed later
			data.push({key:r,value:r});
		}
		
		var ua : db.UserAmap = null;
		var populate :Array<String> = null;
		if (u != null) {
			ua = db.UserAmap.get(u, app.user.amap, true);
			if (ua == null) throw "no user";
			if (ua.rights == null) ua.rights = [];
			//populate form
			populate = ua.rights.map(function(x) return x.getName());
		}
		
		form.addElement( new sugoi.form.elements.CheckboxGroup("rights", "Droits", data, populate, true, true) );
		form.addElement( new sugoi.form.elements.Html("<hr/>"));
		//droits sur des contrats
		var data = [];
		var populate :Array<String> = [];
		data.push({key:"contractAll",value:"Tous les contrats"});
		for (r in app.user.amap.getActiveContracts()) {
			data.push({key:"contract"+Std.string(r.id),value:r.name});
		}
		
		if(ua!=null && ua.rights!=null){
			for ( r in ua.rights) {
				switch(r) {
					case Right.ContractAdmin(cid):
						if (cid == null) {
							populate.push("contractAll");
						}else {
							populate.push("contract"+cid);	
						}
						
					default://
				}
			}
		}
		
		//var r = new haxe.Http("http://www.sfs.chapatiz.com/index/imagepost");
		//r.setPostData("img=" + imgData);
		//r.onData = function(s) trace(s);
		//r.onError = function(s) throw s;
		//r.onStatus = function(s:Int) trace("status " + s);

		form.addElement( new sugoi.form.elements.CheckboxGroup("rights", "Gestion contrats", data, populate, true, true) );
		
		if(form.checkToken()) {
			
			if (u == null) {				
				ua = db.UserAmap.manager.select($userId == Std.parseInt(form.getValueOf("user")) && $amapId == app.user.amap.id, true);
			}
			ua.rights = [];
			//Sys.print(Type.getClass(form.getElement("rights").value));
			var arr : Array<String> = cast form.getElement("rights").value;
			for ( r in arr) {
				if (r.substr(0, 8) == "contract") {
					if (r == "contractAll") {
						ua.rights.push( Right.ContractAdmin() );
					}else {
						ua.rights.push( Right.ContractAdmin(Std.parseInt(r.substr(8)) ) );	
					}
					
				}else {
					ua.rights.push( db.UserAmap.Right.createByName(r) );	
				}
				
			}
			if (ua.rights.length == 0) ua.rights = null;
			ua.update();
			if (ua.rights == null) {
				throw Ok("/amapadmin/rights", "Droits retirés");	
			}else {
				throw Ok("/amapadmin/rights", "Droits créés ou modifiés");
			}
			
		}
		
		if (u == null) {
			view.title = "Créer des droits à un utilisateur";
		}else {
			view.title = "Modifier les droits de "+u.getName();
		}
		
		view.form = form;
		
	}
	
	
}