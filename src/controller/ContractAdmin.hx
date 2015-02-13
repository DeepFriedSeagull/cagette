package controller;
import db.UserContract;
import sugoi.form.elements.Checkbox;
import sugoi.form.elements.Input;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;

class ContractAdmin extends Controller
{

	public function new() 
	{
		super();
		if (!app.user.amap.isAboOk()) throw Redirect("/");
		if (!app.user.isContractManager()) throw Error("/", "Vous n'avez pas accès à la gestion des contrats");
	}
	
	/**
	 * liste les contrats dont on a la responsabilité
	 */
	@tpl("contractadmin/default.mtt")
	function doDefault() {
		
		var contracts = db.Contract.getActiveContracts(app.user.amap, true, false);
		
		
		if (!app.user.isAmapManager()) {
			for ( c in Lambda.array(contracts).copy()) {
				
				if(!app.user.canManageContract(c)) contracts.remove(c);				
			}
		}
		
		view.contracts = contracts;
		
		view.vendors = app.user.amap.getVendors();
		view.places = app.user.amap.getPlaces();
		
		//set a token for delete buttons
		checkToken();
	}
	
	//@tpl("contractadmin/contract.mtt")
	//function doContract(contract:db.Contract) {
		//view.c = contract;
	//}
	
	@tpl("contractadmin/products.mtt")
	function doProducts(contract:db.Contract) {
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = contract;
		
		//generate a token
		checkToken();
	}

	@admin @tpl("form.mtt")
	function doCopyProducts(contract:db.Contract) {
		view.title = "Copier des produits dans : "+contract.name;
		var form = new Form("copy");
		var contracts = app.user.amap.getActiveContracts();
		var contracts  = Lambda.map(contracts, function(c) return {key:Std.string(c.id),value:Std.string(c.name) } );
		form.addElement(new sugoi.form.elements.Selectbox("source","Copier les produits depuis : ",Lambda.array(contracts)));
		form.addElement(new sugoi.form.elements.Checkbox("delete", "Effacer les produits existants (supprime toutes les commandes !)", false));
		if (form.checkToken()) {
			
			if (form.getValueOf("delete") == "1") {
				for ( p in contract.getProducts()) {
					p.lock();
					p.delete();
				}
			}
			
			var source = db.Contract.manager.get(Std.parseInt(form.getValueOf("source")), false);
			var prods = source.getProducts();
			for ( source_p in prods) {
				var p = new db.Product();
				p.name = source_p.name;
				p.price = source_p.price;
				p.type = source_p.type;
				p.contract = contract;
				p.insert();
			}
			
			throw Ok("/contractAdmin/products/" + contract.id, "Produits copiés depuis " + source.name);
			
			
		}
		
		
		view.form = form;
	}
	
	
	/**
	 * experimental !
	 */
	
	/*function setCsvData(data:Array<Dynamic>,headers:Array<String>) {
		if (app.params.exists("csv")) {
			app.setTemplate('empty.mtt');
			neko.Web.setHeader("Content-type", "text.csv");
			neko.Web.setHeader('Content-disposition', 'attachment;filename=export-cagette.csv');
			
			Sys.println(Lambda.map(headers,function(t) return App.t._(t)).join(","));
			
			for (d in data) {
				var row = [];
				//for ( f in Reflect.fields(d)) {
				for( f in headers){
					row.push( Reflect.getProperty(d,f));	
				}
				Sys.println(row.join(","));
			}
			return true;
		}
		return false;
	}*/
	 
	 
	
	@tpl("contractadmin/orders.mtt")
	function doOrders(contract:db.Contract) {
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = contract;
		
		var pids = db.Product.manager.search($contract == contract, false);
		var pids = Lambda.map(pids, function(x) return x.id);
		
		
		var orders = sys.db.Manager.cnx.request("select u.firstName , u.lastName as uname, u.id as uid, p.name as pname ,p.price as price, up.* from User u, UserContract up, Product p where up.userId=u.id and up.productId=p.id and p.contractId="+contract.id+" order by uname asc;").results();
		var totalPrice = 0;
		for ( o in orders) {
			totalPrice += o.quantity * o.price;
		}
		
		if (app.params.exists("csv")) {
			var data = new Array<Dynamic>();
			
			for (o in orders) {
				data.push({"firstName":o.firstName,"uname":o.uname,"pname":o.pname,"price":view.formatNum(o.price),"quantity":o.quantity,"paid":o.paid});				
			}

			setCsvData(data, ["firstName", "uname", "pname", "price", "quantity", "paid"],"Export-"+contract.name+"-Cagette");
			return;
		}
		
		
		view.orders = orders;
		view.totalPrice = totalPrice;
	}
	
	@tpl("contractadmin/distributions.mtt")
	function doDistributions(contract:db.Contract) {
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = contract;
	}
	
	/**
	 * Participation aux distributions
	 */
	@tpl("contractadmin/distributionp.mtt")
	function doDistributionp(contract:db.Contract) {
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		
		var out = new Array<{user:db.User,count:Int}>();
		
		var distribs = contract.getDistribs(false);
		var users = contract.getUsers();
		
		var num =  (distribs.length*contract.distributorNum) / users.length;
		
		view.num = Std.string(num).substr(0,4);
		view.numRounded = Math.round(num);
		view.users = users.length;
		view.distributorNum = contract.distributorNum;
		view.distribs = distribs.length;
		
		for (user in users) {
			App.log(user);
			var count = 0;
			for ( d in distribs) {
				if (d.distributor1Id == user.id) {
					count++;
					continue;
				}
				if (d.distributor2Id == user.id) {
					count++;
					continue;
				}
				if (d.distributor3Id == user.id) {
					count++;
					continue;
				}
				if (d.distributor4Id == user.id) {
					count++;
					continue;
				}
			}
			
			
			out.push( { user:user, count:count } );
		}
		
		view.c = contract;
		view.participations = out;
	}
	
	@tpl("contractadmin/view.mtt")
	function doView(contract:db.Contract) {
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = view.contract = contract;
		
	}
	
	
	@tpl("contractadmin/stats.mtt")
	function doStats(contract:db.Contract, ?args: { stat:Int } ) {
		if (!app.user.canManageContract(contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = contract;
		
		if (args == null) args = { stat:0 };
		view.stat = args.stat;
		
		switch(args.stat) {
			case 0 : 
				//ancienneté des amapiens
				view.anciennete = sys.db.Manager.cnx.request("select YEAR(u.cdate) as uyear ,count(DISTINCT u.id) as cnt from User u, UserContract up where up.userId=u.id and up.productId IN (" + contract.getProducts().map(function(x) return x.id).join(",") + ") group by uyear;").results();
			case 1 : 
				//repartition des commandes
				var pids = db.Product.manager.search($contract == contract, false);
				var pids = Lambda.map(pids, function(x) return x.id);
		
				//view.contracts = sys.db.Manager.cnx.request("select u.firstName , u.lastName as uname, u.id as uid, p.name as pname , up.* from User u, UserContract up, Product p where up.userId=u.id and up.productId=p.id and p.contractId="+contract.id+" order by uname asc;").results();
				
				var repartition = sys.db.Manager.cnx.request("select sum(quantity) as quantity,productId,p.name,p.price from UserContract up, Product p where up.productId IN (" + contract.getProducts().map(function(x) return x.id).join(",") + ") and up.productId=p.id group by productId").results();
				var total = 0;
				var totalPrice = 0;
				for ( r in repartition) {
					total += r.quantity;
					totalPrice += r.price*r.quantity; 
				}
				for (r in repartition) {
					Reflect.setField(r, "percent", Math.round((r.quantity/total)*100)  );
				}
				view.repartition = repartition;
				view.totalQuantity = total;
				view.totalPrice = totalPrice;
				
		}
		
	}
	
	/*@tpl("form.mtt")
	function doInsert(contract:db.Contract) {
		
		var m = new UserContract();
		view.title = "Saisir une commande de \""+contract.name+"\"";
		
		var form = sugoi.form.Form.fromSpod(m);
		
		form.removeElement(form.getElement("amapId"));
		form.removeElement(form.getElement("productId"));
		var products = contract.getProducts();
		var prodArr = [];
		for (p in products) {
			prodArr.push({key:Std.string(p.id),value:p.name});
		}
		form.addElement( new Selectbox("productId", "Produit", prodArr,null,true) );
		
		if (form.isValid()) {
			form.toSpod(m); //update model
			if (!m.user.isMemberOf(app.user.amap)) throw Error('/ContractAdmin', 'Cette personne ne fait pas partie de cette AMAP');
			if (m.user2!=null && !m.user2.isMemberOf(app.user.amap)) throw Error('/ContractAdmin', 'Cette personne ne fait pas partie de cette AMAP');
			m.amap = app.user.amap;
			m.insert();
			
			throw Ok('/contractAdmin/orders/'+m.product.contract.id,'La commande a bien été enregistrée');
		}
		
		view.form = form;
	}*/
	
	/**
	 * Efface une commande
	 * @param	uc
	 */
	function doDelete(uc:UserContract) {
		if (!app.user.canManageContract(uc.product.contract)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		uc.lock();
		uc.delete();
		throw Ok('/contractAdmin/orders/'+uc.product.contract.id,'Le contrat a bien été annulé');
	}
	
	/*@tpl("form.mtt")
	function doEdit(uc:UserContract) {
		
		var form = sugoi.form.Form.fromSpod(uc);
		
		form.removeElement(form.getElement("amapId"));
		form.removeElement(form.getElement("productId"));
		var products = uc.product.contract.getProducts();
		var prodArr = [];
		for (p in products) {
			prodArr.push({key:Std.string(p.id),value:p.name});
		}
		form.addElement( new Selectbox("productId", "Produit", prodArr,Std.string(uc.product.id),true) );
		
		if (form.isValid()) {
			uc.lock();
			form.toSpod(uc); //update model
			uc.update();
			throw Ok('/contractAdmin/orders/' + uc.product.contract.id, 'Ce contrat a été mis à jour');			
		}
		
		view.form = form;
	}*/
	
	/**
	 * Modifier la commande d'un utilisateur
	 */
	@tpl("contractadmin/edit.mtt")
	function doEdit(c:db.Contract, ?user:db.User) {
		if (!app.user.canManageContract(c)) throw Error("/", "Vous n'avez pas le droit de gérer ce contrat");
		view.c = view.contract = c;
		view.u = user;
		
		if (user == null) {
			view.users = app.user.amap.getMembersFormElementData();
		}
		
		var userOrders = new Array<{order:db.UserContract,product:db.Product}>();
		var products = c.getProducts();
		
		for ( p in products) {
			var ua = { order:null, product:p };
			var o = db.UserContract.manager.select($user == user && $productId == p.id, true);
			if (o != null) ua.order = o;
			userOrders.push(ua);
		}
		
		//form check
		if (checkToken()) {
			
			//c'est une nouvelle commande, le user a été défini dans le formulaire
			if (user == null) {
				user = db.User.manager.get(Std.parseInt(app.params.get("user")));
				if (user == null) throw "user #"+app.params.get("user")+" introuvable";
				if (!user.isMemberOf(app.user.amap)) throw user + " ne fait pas partie de cette amap";
			}
			
			
			for (k in app.params.keys()) {
				var param = app.params.get(k);
				if (k.substr(0, "product".length) == "product") {
					
					//trouve le produit dans userOrders
					var pid = Std.parseInt(k.substr("product".length));
					var uo = Lambda.find(userOrders, function(uo) return uo.product.id == pid);
					if (uo == null) throw "Impossible de retrouver le produit " + pid;
					var q = Std.parseInt(param);
					
					var order = new db.UserContract();
					if (uo.order != null) {
						//record existant
						order = uo.order;
						if (q == 0) {
							order.lock();
							order.delete();
						}else {
							order.lock();
							order.quantity = q;
							order.paid = (app.params.get("paid" + pid) == "1");
							order.update();	
						}
					}else {
						//nouveau record
						if (q != 0) {
							order.user = user;
							order.product = uo.product;
							order.quantity = q;
							order.paid = (app.params.get("paid" + pid) == "1");
							order.amap = app.user.amap;
							order.insert();	
						}
					}
				}
			}
			throw Ok("/contractAdmin/orders/" + c.id, "La commande a été mise à jour");
		}
		
		view.userOrders = userOrders;
	}
	
	
	
}