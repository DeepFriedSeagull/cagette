package controller;
import sugoi.form.Form;

class Product extends Controller
{

	public function new()
	{
		super();
		
	}
	
	@tpl('form.mtt')
	function doEdit(d:db.Product) {
		
		var f = sugoi.form.Form.fromSpod(d);
		f.removeElement( f.getElement("type") );
		var pt = new form.ProductTypeRadioGroup("type", "type",Std.string(d.type));
		f.addElement( pt );
		f.removeElementByName("contractId");
		f.getElement("price").addFilter(new sugoi.form.filters.FloatFilter());
			
		if (f.isValid()) {
			//trace(app.params);			
			f.toSpod(d); //update model
			
			d.update();
			throw Ok('/contractAdmin/products/'+d.contract.id,'Le produit a été mis à jour');
		}
		
		view.form = f;
		view.title = "Modifier un produit";
	}
	
	@tpl("form.mtt")
	public function doInsert(contract:db.Contract ) {
		
		if (!app.user.isContractManager(contract)) throw Error("/", "Action interdite"); 
		
		var d = new db.Product();
		var f = sugoi.form.Form.fromSpod(d);
		f.removeElement( f.getElement("type") );
		var pt = new form.ProductTypeRadioGroup("type", "type", "1");
		f.addElement( pt );
		f.removeElementByName("contractId");
		f.getElement("price").addFilter(new sugoi.form.filters.FloatFilter());
		
		if (f.isValid()) {
			f.toSpod(d); //update model
			d.contract = contract;
			d.insert();
			throw Ok('/contractAdmin/products/'+d.contract.id,'Le produit a été enregistrée');
		}
		
		view.form = f;
		view.title = "Enregistrer un nouveau produit";
	}
	
	public function doDelete(p:db.Product) {
		if (checkToken()) {
			var orders = db.UserContract.manager.search($productId == p.id, false);
			if (orders.length > 0) {
				throw Error("/contractAdmin", "Impossible d'effacer ce produit car des commandes y sont rattachées");		
			}
			var cid = p.contract.id;
			p.lock();
			p.delete();
			
			throw Ok("/contractAdmin/products/"+cid,"Produit supprimé");
		}
		throw Error("/contractAdmin", "Erreur de token");
	}
	
}