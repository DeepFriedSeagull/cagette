package controller;
import db.Distribution;
import db.UserContract;
import haxe.web.Dispatch;
import sugoi.tools.ResultsBrowser;

class Main extends Controller {

	@tpl("home.mtt")
	function doDefault() {
		view.category = 'home';
		
		if (app.user != null) {
			
			if(app.user.amap==null) throw Redirect("/user/choose");
		
			var e = new event.Event();
			e.id = "displayHome";
			App.current.eventDispatcher.dispatch(e);

			view.amap = app.user.getAmap();
			
			//contrats ouverts à la commande
			var openContracts = Lambda.filter(app.user.amap.getActiveContracts(), function(c) return c.isUserOrderAvailable());
			view.openContracts = openContracts;
			
			//s'inscrire a une distribution
			view.contractsWithDistributors = Lambda.filter(app.user.getContracts(), function(c) return c.distributorNum > 0);
			
			//DISTRIBUTIONS
 			var orders = app.user.getOrders();
			var contractIds = Lambda.map(orders, function(c) return c.product.contract.id);
			//les distribs dans lesquelles j'ai des produits a prendre
			var distribs = Distribution.manager.search( ($contractId in contractIds) && $end > Date.now(),{orderBy:date,limit:10}, false );
			
			/**
			 * HashMap de jours ( ie "2014-11-01" ), contenant les différentes distrib, pouvant impliquer plusieurs produits (userContracts)
			 */
			var mydistribs = new Map<String, Array<{distrib:Distribution,orders:Array<db.UserContract>}> >();
			
			for ( d in distribs) {
				
				var x = { distrib:d,orders:[] };
				for (order in orders) {
					var contract = order.product.contract;
					if (contract.id == d.contract.id) {
						//trace("CONTRAT "+contract.name+"-"+contract.type+"-"+contract.id);
						
						if (contract.type == db.Contract.TYPE_VARORDER) {
							if (order.distributionId == d.id) {
								//trace("VARY : "+order);
								x.orders.push(order);								
							}
							
						}else {
							//trace("CONSTANT : "+order);
							x.orders.push(order);	
						}
						
					}
				}
				
				
				
				
				
				//do not push empty orders list
				if (x.orders.length > 0) {
					var key = d.end.toString().substr(0,10)+"-p"+d.place.id;				
					var t = mydistribs.get(key);
					if (t == null) {
						t = [];
						mydistribs.set(key, t);
					}
					
					t.push( x );	
				}
				
				
				
			}
			
			//fix bug du sorting (les distribs du jour se mettent en bas)
			var out = [];
			for (x in mydistribs) out.push(x);
			out.sort(function(a, b) {
				return Std.int(a[0].distrib.date.getTime()/1000) - Std.int(b[0].distrib.date.getTime()/1000);
			});
			
			view.distribs = out;	
			
			
			//pass a definir
			view.nopass = (app.user.pass == db.User.EMPTY_PASS);
			
		}else {
			throw Redirect("/user/login");
		}
		
	}
	
	@admin
	function doDb(d:Dispatch) {
		d.parts = []; //desactive haxe.web.Dispatch
		sys.db.Admin.handler();
	}
	
	
	
	//login and stuff
	function doUser(d:Dispatch) {
		d.dispatch(new controller.User());
	}
	
	function doCron(d:Dispatch) {
		d.dispatch(new controller.Cron());
	}
	
	
	@tpl("form.mtt")
	function doInstall() {
		if (db.User.manager.get(1) == null) {
						
			view.title = "Installation de Cagette.net";

			var f = new sugoi.form.Form("c");
			f.addElement(new sugoi.form.elements.Input("amapName", "Nom de votre groupement","",true));
			f.addElement(new sugoi.form.elements.Input("userFirstName", "Votre prénom","",true));
			f.addElement(new sugoi.form.elements.Input("userLastName", "Votre nom de famille","",true));

			if (f.checkToken()) {
	
				var user = new db.User();
				user.firstName = f.getValueOf("userFirstName");
				user.lastName = f.getValueOf("userLastName");
				user.email = "admin@cagette.net";
				user.setPass("admin");
				user.insert();
			
				var amap = new db.Amap();
				amap.name = f.getValueOf("amapName");
				amap.contact = user;

				amap.flags.set(db.Amap.AmapFlags.HasMembership);
				amap.flags.set(db.Amap.AmapFlags.IsAmap);
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
				uc.paid = true;
				uc.quantity = 1;
				uc.insert();
				
				var d = new db.Distribution();
				d.contract = contract;
				d.date = DateTools.delta(Date.now(), 1000.0 * 60 * 60 * 24 * 14);
				d.end = DateTools.delta(d.date, 1000.0 * 60 * 90);
				d.place = place;
				d.insert();
				
				App.current.user = null;
				App.current.session.setUser(user);
				App.current.session.data.amapId  = amap.id;
				
				throw Ok("/", "Groupe et utilisateur 'admin' créé. Votre email est 'admin@cagette.net' et votre mot de passe est 'admin'");
			}	
			
			view.form= f;
			
		}else {
			throw Error("/", "L'utilisateur admin a déjà été créé. Essayez de vous connecter avec admin@cagette.net, mot de passe : admin");
		}
	}
	

	function doP(d:Dispatch) {
		
		/*
		 * Invalid array access
Stack (ADMIN|DEBUG)

Called from C:\HaxeToolkit\haxe\std/haxe/web/Dispatch.hx line 463
Called from controller/Main.hx line 117
		 * 
		var plugin = d.parts.shift();
		for ( p in App.plugins) {
			var n = Type.getClassName(Type.getClass(p)).toLowerCase();
			n = n.split(".").pop();
			if (plugin == n) {
				d.dispatch( p.getController() );
				return;
			}
		}
		
		throw Error("/","Plugin '"+plugin+"' introuvable.");
		*/
		
		d.dispatch(new controller.Plugin());
	}
	

	@logged
	function doMember(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Member());
	}
	
	@logged
	function doTuto(d:Dispatch) {
		
		d.dispatch(new controller.Tuto());
	}
	
	@logged
	function doStats(d:Dispatch) {
		view.category = 'stats';
		d.dispatch(new Stats());
	}
	
	@logged
	function doAccount(d:Dispatch) {
		view.category = 'account';
		d.dispatch(new controller.Account());
	}

	@logged
	function doVendor(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Vendor());
	}
	
	@logged
	function doPlace(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Place());
	}
	
	@logged
	function doDistribution(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Distribution());
	}
	
	@logged
	function doMembership(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Membership());
	}
	
	@logged
	function doShop(d:Dispatch) {
		view.category = 'shop';
		d.dispatch(new controller.Shop());
	}
	
	@logged
	function doProduct(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new controller.Product());
	}
	
	@logged
	function doAmap(d:Dispatch) {
		view.category = 'amap';
		d.dispatch(new controller.Amap());
	}
	
	@logged
	function doContract(d:Dispatch) {
		view.category = 'contract';
		d.dispatch(new Contract());
	}
	
	@logged
	function doContractAdmin(d:Dispatch) {
		view.category = 'contractadmin';
		d.dispatch(new ContractAdmin());
	}
	
	@logged
	function doMessages(d:Dispatch) {
		view.category = 'messages';
		d.dispatch(new Messages());
	}
	
	@logged
	function doAmapadmin(d:Dispatch) {
		view.category = 'amapadmin';
		d.dispatch(new AmapAdmin());
	}
	
	@admin
	function doAdmin(d:Dispatch) {
		d.dispatch(new controller.admin.Admin());
	}
	
	
	
}
