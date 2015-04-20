package controller;
import sugoi.form.Form;

class Place extends Controller
{

	public function new()
	{
		super();
		
	}
	
	@tpl('place/view.mtt')
	function doView(place:db.Place) {
		view.place = place;
		
		//build adress for google maps
		var addr = "";
		if (place.address1 != null)
			addr += place.address1;
			
		if (place.address2 != null) {
			addr += ", " + place.address2;
		}
		
		if (place.zipCode != null) {
			addr += " " + place.zipCode;
		}
		
		if (place.city != null) {
			addr += " " + place.city;
		}
		
		view.addr = view.escapeJS(addr);
		
	}
	
	@tpl('form.mtt')
	function doEdit(d:db.Place) {
		
		var f = sugoi.form.Form.fromSpod(d);
		f.removeElement( f.getElement("amapId") );
			
		if (f.isValid()) {
		
			f.toSpod(d); 
			d.amap = app.user.amap;
			d.update();
			throw Ok('/contractAdmin','Le lieu a été mis à jour');
		}
		
		view.form = f;
		view.title = "Modifier un lieu";
	}
	
	@tpl("form.mtt")
	public function doInsert() {
		
		var d = new db.Place();
		var f = sugoi.form.Form.fromSpod(d);
		f.removeElement( f.getElement("amapId") );
		
		if (f.isValid()) {
			f.toSpod(d); 
			d.amap = app.user.amap;
			d.insert();
			throw Ok('/contractAdmin','Le lieu a été enregistrée');
		}
		
		view.form = f;
		view.title = "Enregistrer un nouveau lieu";
	}
	
}