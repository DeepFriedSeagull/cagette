package form;
import sugoi.form.elements.RadioGroup;
import Common;

class ColorRadioGroup extends RadioGroup
{

	public function new(name:String, label:String,selected:String) 
	{
		var data = [];
		var i = 0;
		for (c in db.CategoryGroup.COLORS) {
			data.push( { key:Std.string(i), value:Std.string(c) } );
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
				
				var img = "<div style='margin-right:16px;width:32px;height:32px;background:"+App.current.view.intToHex(Std.parseInt(row.value))+";'></div>";
				
				s += "<label for=\"" + n+c + "\" class='checkbox' style='display: inline-block;'>"+radio + " "+img+" </label>";
				
				c++;
			}	
		}
		
		return s;
	}
	
	
	
}