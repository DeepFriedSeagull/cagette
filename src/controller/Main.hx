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
		
			if (!app.user.amap.isAboOk()) {
				view.aboOk = false;
				return;
			}else {
				view.aboOk = true;
			}
			
			view.amap = app.user.getAmap();
			
			//s'inscrire a une distribution
			view.contractsWithDistributors = Lambda.filter(app.user.getContracts(), function(c) return c.distributorNum > 0);
			
			//DISTRIBUTIONS
 
			var contracts = app.user.getOrders();
			var contractIds = Lambda.map(contracts, function(c) return c.product.contract.id);
			//les distribs dans lesquelles j'ai des produits a prendre
			var distribs = Distribution.manager.search( ($contractId in contractIds) && $end > Date.now(),{orderBy:date,limit:10}, false );
			
			//contrats ouverts à la commande
			var openContracts = Lambda.filter(app.user.amap.getActiveContracts(), function(c) return c.isUserOrderAvailable());
			view.openContracts = openContracts;
			
			/**
			 * HashMap de jours ( ie "2014-11-01" ), contenant les différentes distrib, pouvant impliquer plusieurs produits (userContracts)
			 */
			var mydistribs = new Map<String, Array<{distrib:Distribution,contracts:Array<db.UserContract>}> >();
			
			for ( d in distribs) {
				
				var x = { distrib:d,contracts:[] };
				for (order in contracts) {
					var contract = order.product.contract;
					if (contract.id == d.contract.id) {
						
						if (contract.type == db.Contract.TYPE_VARORDER) {
							if (order.distributionId == d.id) {
								x.contracts.push(order);
							}
						}else {
							x.contracts.push(order);	
						}
						
					}
				}
				var key = d.end.toString().substr(0,10)+"-p"+d.place.id;
				//trace(key);
				var t = mydistribs.get(key);
				if (t == null) {
					t = [];
					mydistribs.set(key, t);
					//trace("set "+key);
				}
				t.push( x );
				//mydistribs.set(key, t);
				
			}
			
			//fix bug du sorting (les distribis du jour se mettent en bas)
			var out = [];
			for (x in mydistribs) out.push(x);
			out.sort(function(a, b) {
				return Std.int(a[0].distrib.date.getTime()/1000) - Std.int(b[0].distrib.date.getTime()/1000);
			});
			//trace(out);
			view.distribs = out;
			
			//pass a definir
			view.nopass = app.user.pass == "859738d2fed6a98902defb00263f0d35";
			
		}else {
			throw Redirect("/user/login");
		}
		
	}
	
	@admin
	function doDb(d:Dispatch) {
		d.parts = []; //desactive haxe.web.Dispatch
		sys.db.Admin.handler();
	}
	
	@tpl('cgu.mtt')
	function doCgu() {}
	
	//login and stuff
	function doUser(d:Dispatch) {
		d.dispatch(new controller.User());
	}
	
	function doCron(d:Dispatch) {
		d.dispatch(new controller.Cron());
	}
	

	@logged
	function doMember(d:Dispatch) {
		view.category = 'members';
		d.dispatch(new controller.Member());
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
	
	@tpl('form.mtt')
	function doContact() {
		var form = new sugoi.form.Form("contact");
		form.addElement(new sugoi.form.elements.Input("email", "votre email", true));
		form.addElement(new sugoi.form.elements.TextArea("message", "Votre message", "Bonjour...", true,null,"style='width:300px;height:200px;'"));
		view.title = "Formulaire de contact";
		view.form = form;
		
		if (form.checkToken()) {
			var mail = new sugoi.mail.MandrillApiMail();
			mail.setSender(form.getValueOf("email"));
			mail.setSubject("Coucou de Cagette.net");
			mail.setRecipient(App.App.config.get("webmaster_email"), "bibi");
			mail.setHtmlBody("mail/message.mtt", { text:form.getValueOf('message').split("\n").join("<br/>") } );
			mail.send();
			
			throw Ok("/", "Merci, nous allons vous répondre très bientôt.");
		}
		
		
		
	}
	
}
