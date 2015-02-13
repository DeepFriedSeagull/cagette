package controller;
import sugoi.form.Form;

class Account extends Controller
{

	public function new()
	{
		super();
		
	}
	
	
	function doDefault() {
		
	}
	
		
	
	
	@tpl('form.mtt')
	function doEdit() {
		
		var form = sugoi.form.Form.fromSpod(app.user);
		//form.removeElement(form.getElement("amapId"));
		form.removeElement(form.getElement("lang"));
		form.removeElement(form.getElement("pass"));
		form.removeElement(form.getElement("rights"));
		form.removeElement(form.getElement("cdate"));
		form.removeElement(form.getElement("ldate"));
		
		if (form.isValid()) {
			
			if (Std.string(app.user.id) != form.getValueOf("id")) {
				throw "no access";
			}
			var admin = app.user.isAdmin();
			
			form.toSpod(app.user); 
			
			if (!admin) { app.user.rights.unset(Admin); }
			
			app.user.update();
			throw Ok('/contract','Votre compte a été mis à jour');
		}
		
		view.form = form;
		view.title = "Modifier mon compte";
	}
	
	
	
}