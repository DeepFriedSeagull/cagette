package db;
import sys.db.Types;

class Category extends sys.db.Object
{

	public var id : SId;
	public var name :SString<32>;

	@:relation(categoryGroupId) public var categoryGroup:db.CategoryGroup;
	
	/**
	 * renvoie la couleur de la categorie en hexa
	 * @return
	 */
	public function getColor():String {
		return App.current.view.intToHex(db.CategoryGroup.COLORS[categoryGroup.color]);
	}
}