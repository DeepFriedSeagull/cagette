package controller;
#if neko
import neko.Web;
#else
import php.Web;
#end
/**
 * 
 * @author fbarbut
 */
class Controller extends sugoi.BaseController
{

	public function new() 
	{
		super();
	}
	
	/**
	 * 
	 * @param	data
	 * @param	headers
	 */
	function setCsvData(data:Array<Dynamic>,headers:Array<String>,fileName:String) {
		
		app.setTemplate('empty.mtt');
		Web.setHeader("Content-type", "text.csv");
		Web.setHeader('Content-disposition', 'attachment;filename='+fileName+'.csv');
		
		Sys.println(Lambda.map(headers,function(t) return App.t._(t)).join(","));
		
		for (d in data) {
			var row = [];
			//for ( f in Reflect.fields(d)) {
			for( f in headers){
				row.push( "\""+Reflect.getProperty(d,f)+"\"");	
			}
			Sys.println(row.join(","));
		}
		return true;
		
	}
	
}