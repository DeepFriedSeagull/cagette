package controller ;

class Categories extends controller.Controller
{
	@tpl("categories/default.mtt")
	public function doDefault() {
		
		view.groups = db.CategoryGroup.manager.search($amap == app.user.amap, false);
		
		checkToken();
		
	}
	
	/**
	 * genere le set par défaut de catégories
	 */
	public function doGenerate() {
		
		if ( db.CategoryGroup.manager.search($amap == app.user.amap, false).length != 0) {
			throw Error("/amapadmin/categories", "Il existe déjà des catégories");
		}
		
		function gen(catGroupName:String,color:Int,cats:Array<String>) {
			
			var cg = new db.CategoryGroup();
			cg.name = catGroupName;
			cg.color = color;
			cg.amap = app.user.amap;
			cg.insert();
			
			for (c in cats) {
				var x = new db.Category();
				x.categoryGroup = cg;
				x.name = c;
				x.insert();
			}
			
		}
		
		gen("Types de produits",2, ["Légumes", "Fruits", "Poisson", "Viande rouge", "Boulangerie", "Epicerie", "Boissons"]);
		gen("Labels",0, ["Bio certifié", "Bio non certifié", "Conventionnel", "Raisonné"]);
		
		throw Ok("/amapadmin/categories", "Catégories par défaut générées");
		
	}
	
	/**
	 * modifie un groupe de categories
	 */
	@tpl('form.mtt')
	function doEditGroup(g:db.CategoryGroup) {
		
		var form = sugoi.form.Form.fromSpod(g);
		
		form.removeElementByName("color");
		form.removeElementByName("amapId");
		form.addElement(new form.ColorRadioGroup("color", "Couleur", Std.string(g.color)));		
		
		if (form.isValid()) {
			
			form.toSpod(g);
			g.update();
			throw Ok("/amapadmin/categories","Groupe modifié");
			
		}
		
		view.title = "Modifier le groupe " + g.name;
		view.form = form;
	}
	
	@tpl('form.mtt')
	function doInsertGroup() {
		var g = new db.CategoryGroup();
		var form = sugoi.form.Form.fromSpod(g );
		
		form.removeElementByName("color");
		form.removeElementByName("amapId");
		form.addElement(new form.ColorRadioGroup("color", "Couleur", Std.string(g.color)));		
		
		if (form.isValid()) {
			
			form.toSpod(g);
			g.amap = app.user.amap;
			g.insert();
			throw Ok("/amapadmin/categories","Groupe ajouté");
			
		}
		
		view.title = "Créer un groupe de catégories";
		view.form = form;
	}
	
	@tpl('form.mtt')
	function doInsert(g:db.CategoryGroup) {
		var c = new db.Category();
		var form = sugoi.form.Form.fromSpod(c);
		
		form.removeElementByName("categoryGroupId");
		
		if (form.isValid()) {
			
			form.toSpod(c);
			c.categoryGroup = g;
			c.insert();
			throw Ok("/amapadmin/categories","Catégorie ajoutée");
			
		}
		
		view.title = "Créer une catégorie";
		view.form = form;
	}
	
	
	@tpl('form.mtt')
	function doEdit(c:db.Category) {
		
		var form = sugoi.form.Form.fromSpod(c);
		
		form.removeElementByName("categoryGroupId");
		
		if (form.isValid()) {
			
			form.toSpod(c);
			c.update();
			throw Ok("/amapadmin/categories","Catégorie modifiée");			
		}
		
		view.title = "Modifier la catégorie " + c.name;
		view.form = form;
	}
	
	
	function doDeleteGroup(g:db.CategoryGroup,args:{token:String}) {
		
		if ( checkToken()) {
			if (g.getCategories().length > 0) throw Error("/amapadmin/categories", "Vous devez effacer d'abord les catégories de ce groupe avant de supprimer ce groupe.");	
			
			g.lock();
			g.delete();
			throw Ok("/amapadmin/categories", "Groupe effacé");
		}else {
			throw Redirect("/amapadmin/categories");
		}
	}
	
	function doDelete(c:db.Category,args:{token:String}) {
		
		if ( checkToken()) {
			c.lock();
			c.delete();
			throw Ok("/amapadmin/categories", "Catégorie effacée");
		}else {
			throw Redirect("/amapadmin/categories");
		}
	}
	
	
	
	
}