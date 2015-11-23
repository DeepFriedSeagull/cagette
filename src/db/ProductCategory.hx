package db;
import sys.db.Types;

@:id(productId,categoryId)
class ProductCategory extends sys.db.Object
{
	
	@:relation(productId)
	public var product : db.Product;
	
	@:relation(categoryId)
	public var category : db.Category;
	
	#if neko
	public var productId : SInt;
	public var categoryId : SInt;
	#end
}