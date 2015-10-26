package ;
import Common;
/**
 * Permet de tagger les produits à partir de la liste de categories
 * @author fbarbut<francois.barbut@gmail.com>
 */
@:keep
class Tagger
{

	var contractId : Int;
	var data:TaggerInfos;
	
	public function new(cid:Int) 
	{
		contractId = cid;
	}
	
	public function init() {
		
		
		var req = new haxe.Http("/product/categorizeInit/"+contractId);
		req.onData = function(_data) {			
			data = haxe.Json.parse(_data);		
			render();
		}
		req.request();
		
	}
	
	function render() {
		var html = new StringBuf();
		html.add("<table class='table'>");
		for (p in data.products) {
			html.add("<tr class='p"+p.product.id+"'>");
			html.add("<td><input type='checkbox' name='p"+p.product.id+"' /></td>");
			html.add("<td>" + p.product.name+"</td>");
			var tags = [];
			for (c in p.categories) {
				//trouve le nom du tag
				var name = "";
				var color = "";
				for (gc in data.categories) {
					for ( t in gc.tags) {
						if (c == t.id) {
							name = t.name;
							color = gc.color;
						}
					}
				}
				//var bt = App.j("<a>[X]</a>")
				tags.push("<span class='tag t"+c+"' style='background-color:"+color+";cursor:pointer;'>"+name+"</span>");
			}
			
			html.add("<td class='tags'>"+ tags.join(" ") +"</td>");
			html.add("</tr>");
		}
		html.add("</table>");
		App.j("#tagger").html(html.toString());
		App.j("#tagger .tag").click(function(e) {
			
			//find tag Id
			var tid = Std.parseInt(e.currentTarget.getAttribute('class').split(" ")[1].substr(1));
			trace("tag " +tid );
					
			//find product Id					
			var pid = Std.parseInt(e.currentTarget.parentElement.parentElement.getAttribute('class').substr(1));
			trace("product " + pid);
			
			//remove element 
			e.currentTarget.remove();
			
			//datas
			remove(tid,pid);
		});
		
	}
	
	public function add() {
		var tagId = Std.parseInt(App.j("#tag").val());
		if (tagId == 0) js.Browser.alert("Impossible de trouver la catégorie selectionnée");
		
		var pids = [];
		for ( e in App.j("#tagger input:checked")) {
			pids.push(Std.parseInt(e.attr("name").substr(1)));
		}
		if (pids.length == 0) js.Browser.alert("Sélectionnez un produit afin de pouvoir lui attribuer une catégorie");
		
		for (p in pids) {
			addTag(tagId, p);
		}
		
		render();
	}
	
	public function remove(tagId:Int,productId:Int) {
		//data
		for ( p in data.products) {
			if (p.product.id == productId) {
				for ( t in p.categories) {
					if (t == tagId) p.categories.remove(t);
				}
			}
		}
	}
	
	function addTag(tagId:Int,productId:Int) {
		//check for doubles
		for ( p in data.products) {
			if (p.product.id == productId) {
				for (t in p.categories) {
					if (t == tagId) return;
				}
			}
		}
		
		//data
		for ( p in data.products) {
			if (p.product.id == productId) {
				p.categories.push(tagId);
				break;
			}
		}
	}
	
	public function submit() {
		
		
		var req = new haxe.Http("/product/categorizeSubmit/" + contractId);
		req.addParameter("data", haxe.Json.stringify(data));
		req.onData = function(_data) {			
			
			js.Browser.alert(_data);
		}
		req.request(true);
		
	}
	
}