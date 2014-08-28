rpm:
	rm -rf try
	mkdir try
	cp -ar container templates public start_try_tarantool.lua try_tarantool.lua README.md 	./try
	tar -c --exclude .git -f - try | gzip >try.tar.gz
	rpmbuild -bb --define "_sourcedir `pwd`" --define "_rpmdir `pwd`" try.spec
