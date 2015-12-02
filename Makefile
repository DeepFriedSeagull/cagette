ROPTS=-zav --no-p --chmod=u=rwX,g=rX,o= --delete --exclude=www/.htaccess --exclude=.svn --exclude=.git --exclude=*.mtt --exclude=tpl/css --exclude=www/file
LANG=fr

compile:
	haxe project.hxml

css:
	hss hss/*.hss -output www/css/

templates:
	(cd lang/$(LANG)/tpl; temploc2 -macros macros.mtt -output ../tmp/ *.mtt */*.mtt */*/*.mtt)

deploy: 
	#compile
	#css
	@make LANG=fr templates
	@make LANG=fr deploy_site deploy_tpl

deploy_site:
	rsync $(ROPTS) www www-data@www.cagette.net:/data/cagette/

deploy_tpl:
	rsync $(ROPTS) lang/$(LANG) www-data@www.cagette.net:/data/cagette/lang/
	

bundle:
	@make LANG=fr templates
	haxe cagette.hxml
	rm -rf www/file/*.jpg
	tar -cvf cagette.tar www config.xml.dist lang
	scp cagette.tar www-data@cagette.net:/data/cagetteSite/www/
	rm cagette.tar
	
	

	