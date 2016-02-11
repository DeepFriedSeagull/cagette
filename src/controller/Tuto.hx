package controller;

/**
 * ...
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Tuto extends sugoi.BaseController
{

	/**
	 * TUTO "AMAP"
	 * @param	step
	 */
	public function doAmap(step:Int) {
		
		
		App.current.setTemplate("tuto/amap/"+step+".mtt");
	}
	
	
	@tpl("tuto/cancel.mtt")
	function doCancel() {}
	
	
	
}