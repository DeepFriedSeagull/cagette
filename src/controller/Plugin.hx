package controller;

/**
 * ...
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Plugin extends sugoi.BaseController
{

	public function new() 
	{
		super();
	}
	#if plugins
	//cagette-hosted
	public function doHosted(d:haxe.web.Dispatch) {
		d.dispatch(new hosted.controller.Main());
	}	
	#end
	
}