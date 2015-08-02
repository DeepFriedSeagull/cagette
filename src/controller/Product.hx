package controller;
import sugoi.form.Form;
import Common;
using Std;
class Product extends Controller
{

	public function new()
	{
		super();
		
	}
	
	@tpl('form.mtt')
	function doEdit(d:db.Product) {
		
		if (!app.user.canManageContract(d.contract)) throw "Accès interdit";
		
		var f = sugoi.form.Form.fromSpod(d);
		
		f.removeElement( f.getElement('imageId') );		
		
		//type (->icon)
		f.removeElement( f.getElement("type") );
		var pt = new form.ProductTypeRadioGroup("type", "type",Std.string(d.type));
		f.addElement( pt );
		
		//vat selector
		f.removeElement( f.getElement('vat') );		
		var data = [];
		for (k in app.user.amap.vatRates.keys()) {
			data.push( { key:app.user.amap.vatRates[k].string(), value:k } );
		}
		f.addElement( new sugoi.form.elements.Selectbox("vat", "TVA", data, Std.string(d.vat) ) );

		f.removeElementByName("contractId");
		f.getElement("price").addFilter(new sugoi.form.filters.FloatFilter());
			
		if (f.isValid()) {
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
		
		f.removeElement( f.getElement('imageId') );	
		
		f.removeElement( f.getElement("type") );		
		var pt = new form.ProductTypeRadioGroup("type", "type", "1");
		f.addElement( pt );
		f.removeElementByName("contractId");
		f.getElement("price").addFilter(new sugoi.form.filters.FloatFilter());
		
		
		//vat selector
		f.removeElement( f.getElement('vat') );
		
		var data = [];
		for (k in app.user.amap.vatRates.keys()) {
			data.push( { key:app.user.amap.vatRates[k].string(), value:k } );
		}
		f.addElement( new sugoi.form.elements.Selectbox("vat", "TVA", data, Std.string(d.vat) ) );
		
		
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
		
		if (!app.user.canManageContract(p.contract)) throw "Accès interdit";
		
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
	
	
	@tpl('product/import.mtt')
	function doImport(c:db.Contract, ?args: { confirm:Bool } ) {
		
		if (!app.user.canManageContract(c)) throw "Accès interdit";
			
		var step = 1;
		var request = sugoi.tools.Utils.getMultipart(1024 * 1024 * 4);
		view.contract = c;
		
		//on recupere le contenu de l'upload
		if (request.get("file") != null) {
			
			var csv = new sugoi.tools.Csv();
			var datas = csv.importDatas(request.get("file"));
			
			app.session.data.csvImportedData = datas;

			view.data = datas;
			
			step = 2;
		}
		
		if (args != null && args.confirm) {
			var i : Iterable<Dynamic> = cast app.session.data.csvImportedData;
			for (p in i) {
				if (p[0] == null || p[0] == "") continue;

				var product = new db.Product();
				product.name = p[0];
				
				var fv = new sugoi.form.filters.FloatFilter();
				product.price = fv.filter(p[1]);
				product.contract = c;
				product.insert();
				
			}
			
			view.numImported = app.session.data.csvImportedData.length;
			app.session.data.csvImportedData = null;
			
			step = 3;
		}
		
		if (step == 1) {
			//reset import when back to import page
			app.session.data.csvImportedData =	null;
		}
		
		view.step = step;
	}
	
	@tpl("product/categorize.mtt")
	public function doCategorize(contract:db.Contract) {
		
		if (!app.user.canManageContract(contract)) throw "Accès interdit";
		
		if (db.CategoryGroup.get(app.user.amap).length == 0) throw Error("/contractAdmin", "Vous devez d'abord définir des catégories avant de pouvoir catégoriser vos produits");
		
		//var form = new sugoi.form.Form("cat");
		//
		//for ( g in db.CategoryGroup.get(app.user.amap)) {
			//var data = [];
			//for ( c in g.getCategories()) {
				//data.push({key:Std.string(c.id),value:c.name});
			//}
			//form.addElement(new sugoi.form.elements.Selectbox("cats"+g.id,g.name,data));
		//}
		//
		//view.form = form;
		view.c = contract;
		
	}
	
	/**
	 * init du Tagger
	 * @param	contract
	 */	
	public function doCategorizeInit(contract:db.Contract) {
		
		if (!app.user.canManageContract(contract)) throw "Accès interdit";
		
		var data : TaggerInfos = {
			products:[],
			categories:[]
		}
		
		for (p in contract.getProducts()) {
			
			data.products.push({product:p.infos(),categories:Lambda.array(Lambda.map(p.getCategories(),function(x) return x.id))});
		}
		
		for (cg in db.CategoryGroup.get(app.user.amap)) {
			
			var x = { id:cg.id, categoryGroupName:cg.name, color:App.current.view.intToHex(db.CategoryGroup.COLORS[cg.color]),tags:[] };
			
			for (t in cg.getCategories()) {
				x.tags.push({id:t.id,name:t.name});
			}
			data.categories.push(x);
			
		}
		
		Sys.print(haxe.Json.stringify(data));
	}
	
	public function doCategorizeSubmit(contract:db.Contract) {
		
		if (!app.user.canManageContract(contract)) throw "Accès interdit";
		
		var data : TaggerInfos = haxe.Json.parse(app.params.get("data"));
		
		db.ProductCategory.manager.unsafeDelete("delete from ProductCategory where productId in (" + Lambda.map(contract.getProducts(), function(t) return t.id).join(",")+")");
		
		for (p in data.products) {
			for (t in p.categories) {
				var x = new db.ProductCategory();
				x.categoryId = t;
				x.productId = p.product.id;
				x.insert();
				
			}
		}
		
		Sys.print("Modifications enregistrées");
		
	}
	
	
	@tpl('product/addimage.mtt')
	function doAddImage(product:db.Product) {
		
		if (!app.user.canManageContract(product.contract)) throw "Accès interdit";
		
		view.c = product.contract;
		view.image = product.image;
		
		var request = sugoi.tools.Utils.getMultipart(1024*1024); //1M
		if (request.exists("image")) {
			
			
			
			//Image
			var image = request.get("image");
			if (image !=null && image.length > 0) {
				var img = sugoi.db.File.create(image);
				product.lock();
				
				if (product.image != null) {
					//efface ancienne
					product.image.lock();
					product.image.delete();
				}
				
				product.image = img;
				product.update();
				throw Ok('/product/addImage/'+product.id,'Image mise à jour');
			}
		}
	}	
}