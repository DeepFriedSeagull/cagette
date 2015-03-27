package controller.admin;

/**
 * ...
 * @author fbarbut<francois.barbut@gmail.com>
 */
class Plugins extends controller.Controller
{

	public function new() 
	{
		super();	
	}
	
	@tpl("admin/plugins/default.mtt")
	public function doDefault() {
		view.plugins = App.plugins;
	}
	
	
	public function doInstall(plugin:String) {
		
		var p = App.getPlugin(plugin);
		if (p == null) throw Error("/admin/plugins","Le plugin '"+plugin+"' introuvable");
		
		if(p.isInstalled()) throw Ok("/admin/plugins","Le plugin '"+plugin+"' est déjà installé");
		p.install();
		throw Ok("/admin/plugins","Le plugin '"+plugin+"' est correctement installé");
		
	}
	
}