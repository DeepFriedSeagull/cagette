package form;
import db.Product;
import sugoi.form.elements.RadioGroup;
import db.Product;
import Common;
/**
 * list des types de produits avec image
 * @author 
 */
class ProductTypeRadioGroup extends RadioGroup
{

	public function new(name:String, label:String,selected:String) 
	{
		var data = [];
		var i = 0;
		for (e in Type.getEnumConstructs(ProductType)) {
			data.push( { key:Std.string(i), value:Std.string(e) } );
			i++;
		}
		
		super(name, label, data, selected, "1", false, true);
	}
	
	override public function render():String
	{
		var s = "";
		var n = parentForm.name + "_" +name;
		
		var c = 0;
		if (data != null)
		{
			for (row in data)
			{
				
				
				var radio = "<input type=\"radio\" name=\""+n+"\" id=\""+n+c+"\" value=\"" + row.key + "\" " + (row.key == Std.string(value) ? "checked":"") +" />\n";
				var e = Type.createEnumIndex(ProductType, Std.parseInt(row.key));
				var img = "<img src='/img/"+Std.string(e).toLowerCase().substring(2)+".png' />";
				
				s += "<label for=\"" + n+c + "\" class='checkbox' style='display: inline-block;'>"+radio + " "+img+" </label>";
				
				c++;
			}	
		}
		
		return s;
	}
	
}