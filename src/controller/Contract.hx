package controller;
import db.UserContract;
import sugoi.form.elements.DateDropdowns;
import sugoi.form.elements.Hidden;
import sugoi.form.elements.Input;
import sugoi.form.elements.Selectbox;
import sugoi.form.Form;

class Contract extends Controller
{

	public function new() 
	{
		super();
	}
	
	/**
	 * contrats de l'utilisateur en cours
	 */
	@tpl("contract/default.mtt")
	function doDefault() {
		
		var userContracts = app.user.getOrders();
		view.userContracts = userContracts;
	}
	
	
	//function form() {
	//
		//var form = new Form("contract");
		//form.addElement( new Hidden("id", "id") );
		//form.addElement( new Input("name", "Nom") );
		//form.addElement( new DateDropdowns("startDate", "Date de début") );
		//form.addElement( new DateDropdowns("endDate", "Date de fin") );
		//form.addElement( new Selectbox("userId", "Responsable", app.user.amap.getMembersFormElementData()));
		//var vendors = db.Vendor.manager.search($amap == app.user.amap, false);
		//var v = [];
		//for (vendor in vendors) v.push({key:Std.string(vendor.id),value:vendor.name});
		//form.addElement( new Selectbox("vendorId", "Producteur", v));		
		//return form;
		//
	//}
	
	@tpl("form.mtt")
	function doEdit(c:db.Contract) {
		
		if (!app.user.isContractManager(c)) throw Error('/', 'Action interdite');
		var currentContact = c.contact;
		var form = Form.fromSpod(c);
		form.removeElement( form.getElement("amapId") );
		
		if (form.checkToken()) {
			form.toSpod(c);
			c.amap = app.user.amap;
			c.update();
			
			//update rights
			if ( c.contact != null && (currentContact==null || c.contact.id!=currentContact.id) ) {
				var ua = db.UserAmap.get(c.contact, app.user.amap, true);
				ua.giveRight(ContractAdmin(c.id));
				ua.giveRight(Messages);
				ua.giveRight(Membership);
				ua.update();
				
				//remove rights to old contact
				if (currentContact != null) {
					
					var x = db.UserAmap.get(currentContact, c.amap, true);
					if (x == null) throw currentContact+" n'a aucun lien avec "+c.amap.name;
					//App.log("avant "+x.rights);
					x.removeRight(ContractAdmin(c.id));
					x.update();	
					//App.log("apres "+x.rights);
				}
				
			}
			
			throw Ok("/contractAdmin/view/"+c.id, "Contrat mis à jour");
		}
		
		view.form = form;
	}
	
	@tpl("form.mtt")
	function doInsert() {
		if (!app.user.isAmapManager()) throw Error('/', 'Action interdite');
		
		var c = new db.Contract();
		
		var form = Form.fromSpod(c);
		form.removeElement( form.getElement("amapId") );
		
		if (form.checkToken()) {
			form.toSpod(c);
			c.amap = app.user.amap;
			c.insert();
			
			//right
			if (c.contact != null) {
				var ua = db.UserAmap.get(c.contact, app.user.amap, true);
				ua.giveRight(ContractAdmin(c.id));
				ua.giveRight(Messages);
				ua.giveRight(Membership);
				ua.update();
			}
			
			throw Ok("/contractAdmin/view/"+c.id, "Nouveau contrat créé");
		}
		
		view.form = form;
	}
	
	function doDelete(c:db.Contract/*,args:{chk:String}*/) {
		if (checkToken()) {
			
			//verif qu'il n'y a pas de commandes sur ce contrat
			var products = c.getProducts();
			var orders = db.UserContract.manager.count($productId in Lambda.map(products, function(p) return p.id));
			if (orders > 0) {
				throw Error("/contractAdmin", "Vous ne pouvez pas effacer ce contrat car il y a des commandes rattachées à ce contrat.");
			}
			
			//remove admin rights and delete contract		
			var ua = db.UserAmap.get(c.contact, c.amap, true);
			if (ua != null) {
				ua.removeRight(ContractAdmin(c.id));
				ua.update();	
			}	
			c.lock();
			c.delete();
			throw Ok("/contractAdmin", "Contrat supprimé");
			
		}
		
		throw Error("/contractAdmin","Erreur de token");
	}
	
	@tpl("contract/order.mtt")
	function doOrder(c:db.Contract) {
		if (!c.isUserOrderAvailable()) throw Error("/", "Ce contrat n'est pas ouvert aux commandes ");
		
		view.c = view.contract = c;
		
		var userOrders = new Array<{order:db.UserContract,product:db.Product}>();
		var products = c.getProducts();
		
		for ( p in products) {
			var ua = { order:null, product:p };
			var o = db.UserContract.manager.select($user == app.user && $productId == p.id, true);
			if (o != null) ua.order = o;
			userOrders.push(ua);
		}
		
		//form check
		if (checkToken()) {
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
							order.paid = (q==order.quantity && order.paid); //si deja payé et quantité inchangée
							order.quantity = q;						
							order.update();	
						}
					}else {
						//nouveau record
						if (q != 0) {
							order.user = app.user;
							order.product = uo.product;
							order.quantity = q;
							order.paid = false;
							order.amap = app.user.amap;
							order.insert();	
						}
					}
				}
			}
			throw Ok("/contract/order/" + c.id, "Votre commande a été mise à jour");
		}
		
		view.userOrders = userOrders;
		
	}
	
	
}