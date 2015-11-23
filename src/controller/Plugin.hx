package controller;

/**
 * Base controller for plugins
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Plugin extends sugoi.BaseController
{

	public function new() 
	{
		super();
	}
	
	public function doDefault() {
		
	}
	
	#if plugins
	//cagette-hosted
	public function doHosted(d:haxe.web.Dispatch) {
		d.dispatch(new hosted.controller.Main());
	}	
	#end
	
}